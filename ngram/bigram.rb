require 'bundler'
Bundler.require

class FileReader
  def initialize (file_name)
    @file_name = file_name
  end

  def count_by_word
    return @count_by_word if !@count_by_word.nil?

    @count_by_word = {}
    @count_all_word = 0
    File.open(@file_name, 'r') do |file|
      file.each_line do |line|
        words = line.split(' ')
        words.each do |word|
          word = word.to_i
          @count_by_word[word] ||= 0
          @count_by_word[word] += 1
          @count_all_word += 1
        end
      end
    end

    @count_by_word
  end

  def count_all_word
    @count_all_word
  end

  def count_by_word_after_targets (targets)
    return @count_by_word_after_target if !@count_by_word_after_target.nil?

    @count_by_word_after_target = {}
    @count_word_after_target = 0
    File.open(@file_name, 'r') do |file|
      file.each_line do |line|
        words = line.split(' ')
        words.each_with_index do |word, index|
          i = 0
          next_flg = false
          targets.each do |target|
            if target != words[index + i].to_i
              next_flg = true
              break
            end
            i += 1
          end

          next if next_flg

          next_word = words[index + i].to_i
          @count_by_word_after_target[next_word] ||= 0
          @count_by_word_after_target[next_word] += 1
          @count_word_after_target += 1
        end
      end
    end

    @count_by_word_after_target
  end

  def count_word_after_target
    @count_word_after_target
  end
end

class Ngram
  def initialize
    file_name, target_words, model = argv
    file_reader = FileReader.new(file_name)

    @ngram = model.new file_reader, target_words
  end

  def calc
    @ngram.calc
  end

  FILE_ROWS = 13939

  def self.output_to_file (ngram_model, output_file_name)
    File.open(output_file_name, 'w+') do |file|
      i = 1
      file.write(sprintf("%20.17e\n", 0)) # for unknown word
      ngram_model.each do |word, p|
        p ||= 0
        file.write(sprintf("%20.17e\n", p))
        i += 1
      end

      if i != FILE_ROWS
        puts "Invalid model rows. (model rows: #{i}, correct model rows: #{FILE_ROWS})"
        exit 1
      end
    end
    puts "Finished to write to file. (file name: #{output_file_name})"
  end

  private

  def argv
    if ARGV[0].nil?
      puts 'file name is required.'
      exit 1
    end
    file_name = ARGV[0].to_str

    model = nil
    case ARGV[1]
      when 'bigram'
        model = Bigram
      when 'trigram'
        model = Trigram
      else
        puts 'model_name is required.'
        exit 1
    end

    if ARGV[2].nil?
      puts 'target_word is required.'
      exit 1
    end

    target_words = JSON.parse ARGV[2], { :max_nesting => 1 }
    if !target_words.is_a?(Array)
      puts 'target word is not array.'
      exit 1
    end

    case model
      when Bigram
        if target_words.count != 1
          puts 'Invalid target_word count.'
        end
      when Trigram
        if target_words.count != 2
          puts 'Invalid target_word count.'
        end
    end

    target_words.each_with_index do |word, index|
      target_words[index] = word.to_i
    end

    [file_name, target_words, model]
  end
end

class Bigram < Ngram
  OUTPUT_FILE_PREFIX = 'data/bigram_'

  def initialize (file_reader, target_words)
    @file_reader = file_reader
    @target_words = target_words
    @target_word = target_words[0]
  end

  def calc
    bigram_model, sum_p = kneser_ney
    bigram_model = good_turing_distribution bigram_model, sum_p

    Ngram::output_to_file bigram_model, "#{OUTPUT_FILE_PREFIX}#{@target_word}"
  end

  private

  CONST_D = 0.75

  def kneser_ney
    count_by_word_after_target = @file_reader.count_by_word_after_targets(@target_words)
    count_by_word = @file_reader.count_by_word
    count_all_word = @file_reader.count_all_word

    bigram_model = {}
    sum_p = 0.0
    count_by_word.each do |word,|
      count_by_word_after_target[word] ||= 0
      p = [count_by_word_after_target[word].to_f - CONST_D, 0.0].max /
        count_by_word[@target_word].to_f + count_by_word[word].to_f / count_all_word.to_f
      bigram_model[word] = p
      sum_p += p
    end

    [bigram_model, sum_p]
  end

  def good_turing_distribution (bigram_model, sum_p)
    count_by_word = @file_reader.count_by_word
    count_all_word = @file_reader.count_all_word

    bigram_model.each do |word, p|
      bigram_model[word] = p + (1.0 - sum_p) * count_by_word[word].to_f / count_all_word.to_f
    end
    bigram_model
  end
end

class Trigram < Ngram
  OUTPUT_FILE_PREFIX = 'data/trigram_'

  def initialize (file_reader, target_words)
    @file_reader = file_reader
    @target_words = target_words
  end

  def calc
    trigram_model, sum_p = kneser_ney
    trigram_model = good_turing_distribution trigram_model, sum_p

    Ngram::output_to_file trigram_model, "#{OUTPUT_FILE_PREFIX}#{@target_words[0]}_#{@target_words[1]}"
  end

  private

  CONST_D = 0.5

  def kneser_ney
    count_by_word_after_targets = @file_reader.count_by_word_after_targets(@target_words)
    count_all_word_after_targets = count_all_word_after_targets count_by_word_after_targets
    count_by_word = @file_reader.count_by_word

    trigram_model = {}
    pre_sum_p = 0.0
    count_by_word.each do |word,|
      p = [count_by_word_after_targets[word].to_f - CONST_D, 0.0].max / count_all_word_after_targets.to_f
      trigram_model[word] = p
      pre_sum_p += p
    end

    bigram_model = bigram_model()

    sum_p = 0.0
    trigram_model.each do |word, p|
      trigram_model[word] = p + (1.0 - pre_sum_p) * bigram_model[word]
      sum_p += trigram_model[word]
    end

    [trigram_model, sum_p]
  end

  def bigram_model
    bigram_file_name = Bigram::OUTPUT_FILE_PREFIX + @target_words[1].to_s

    if !File.exists? bigram_file_name
      bigram = Bigram.new @file_reader, [@target_words[1]]
      bigram.calc
    end

    i = 0
    bigram_model = {}
    File.open(bigram_file_name, 'r') do |file|
      file.each_line do |line|
        bigram_model[i] = line.to_f
        i += 1
      end
    end

    bigram_model
  end

  def good_turing_distribution (trigram_model, sum_p)
    count_by_word = @file_reader.count_by_word
    count_all_word = @file_reader.count_all_word

    trigram_model.each do |word, p|
      trigram_model[word] = p + (1.0 - sum_p) * count_by_word[word].to_f / count_all_word.to_f
    end
    trigram_model
  end

  def count_all_word_after_targets (count_by_word_after_targets)
    sum_count = 0
    count_by_word_after_targets.each do |word, count|
      sum_count += count
    end
    sum_count
  end
end

ngram = Ngram.new
ngram.calc