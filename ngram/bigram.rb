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

  def count_by_word_after_target (target)
    return @count_by_word_after_target if !@count_by_word_after_target.nil?

    @count_by_word_after_target = {}
    @count_word_after_target = 0
    File.open(@file_name, 'r') do |file|
      file.each_line do |line|
        words = line.split(' ')
        words.each_with_index do |word, index|
          if word.to_i == target
            next_word = words[index + 1].to_i
            @count_by_word_after_target[next_word] ||= 0
            @count_by_word_after_target[next_word] += 1
            @count_word_after_target += 1
          end
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
    file_name, target_word, n = argv
    file_reader = FileReader.new(file_name)

    case n
      when 2
        @ngram = Bigram.new file_reader, target_word
      when 3
        @ngram = Trigram.new file_reader, target_word
      else
        puts 'bigram and trigram are only inplemented.'
        exit 1
    end
  end

  def calc
    @ngram.calc
  end

  def output_to_file (ngram_model, output_file_name)
    File.open(output_file_name, 'w+') do |file|
      file.write(sprintf("%20.17e\n", 0)) # for unknown word
      ngram_model.each do |word, p|
        p ||= 0
        file.write(sprintf("%20.17e\n", p))
      end
    end
  end

  private

  def argv
    if ARGV[0].nil?
      puts 'file name is required.'
      exit 1
    end
    file_name = ARGV[0].to_str

    if ARGV[1].nil?
      puts 'target_word_num is required.'
      exit 1
    end
    target_word_num = ARGV[1].to_i

    if ARGV[2].nil?
      puts 'n is required.'
      exit 1
    end
    n = ARGV[2].to_i

    [file_name, target_word_num, n]
  end
end

class Bigram < Ngram
  OUTPUT_FILE_PREFIX = 'data/bigram_'

  def initialize (file_reader, target_word)
    @file_reader = file_reader
    @target_word = target_word
  end

  def calc
    # discounted_bigram, sum_p = discounting
    # bigram_model = distribution discounted_bigram, sum_p

    bigram_model, sum_p = kneser_ney
    bigram_model = good_turing_distribution bigram_model, sum_p

    this.output_to_file bigram_model, "#{OUTPUT_FILE_PREFIX}#{@target_word}"
  end

  private

  def good_turing_distribution (discounted_bigram, sum_p)
    count_by_word = @file_reader.count_by_word
    count_all_word = @file_reader.count_all_word

    bigram_model = {}
    discounted_bigram.each do |word, p|
      bigram_model[word] = p + (1.0 - sum_p) * count_by_word[word].to_f / count_all_word.to_f
    end
    bigram_model
  end

  CONST_D = 0.5

  def kneser_ney
    count_by_word_after_target = @file_reader.count_by_word_after_target(@target_word)
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

  # not used
  # def discounting
  #   count_by_word_after_target = @file_reader.count_by_word_after_target(@target_word)
  #   count_word_after_target = @file_reader.count_word_after_target
  #   count_by_word = @file_reader.count_by_word
  #
  #   discounted_bigram = {}
  #   word_count_by_count = word_count_by_count()
  #   sum_p = 0.0
  #
  #   count_by_word.each do |word,|
  #     count_after_target = count_by_word_after_target[word] || 0
  #     word_count_by_count[count_after_target + 1] ||= 0.0
  #
  #     if word_count_by_count[count_after_target] != 0
  #       discounted_count = (count_after_target + 1).to_f *
  #           word_count_by_count[count_after_target + 1].to_f /
  #           word_count_by_count[count_after_target].to_f
  #     else
  #       discounted_count = 0
  #     end
  #
  #     discounted_bigram[word] = discounted_count / count_word_after_target
  #     sum_p += discounted_bigram[word]
  #   end
  #
  #   [discounted_bigram, sum_p]
  # end

  # not used
  # def word_count_by_count
  #   count_by_word_after_target = @file_reader.count_by_word_after_target(@target_word)
  #   count_by_word = @file_reader.count_by_word
  #
  #   word_count_by_count = {}
  #   count_by_word.each do |word,|
  #     count = count_by_word_after_target[word] || 0
  #
  #     word_count_by_count[count] ||= 0
  #     word_count_by_count[count] += 1
  #   end
  #   word_count_by_count
  # end
end

class Trigram < Ngram
  OUTPUT_FILE_PREFIX = 'data/trigram_'

  def initialize (file_reader, target_word)
    @file_reader = file_reader
    @target_word = target_word
  end

  def calc
    trigram_model, sum_p = kneser_ney
    trigram_model = good_turing_distribution trigram_model, sum_p

    this.output_to_file trigram_model, "#{OUTPUT_FILE_PREFIX}#{@target_word}"
  end
end

ngram = Ngram.new
ngram.calc