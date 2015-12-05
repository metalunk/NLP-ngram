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

class Bigram
  OUTPUT_FILE_PREFIX = 'data/bigram_'

  def initialize
    file_name, @target_word = argv
    @file_reader = FileReader.new(file_name)
  end

  def calc
    discounted_bigram, sum_p = discounting
    bigram_model = distribution discounted_bigram, sum_p

    output_to_file bigram_model
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

    [file_name, target_word_num]
  end

  def discounting
    count_by_word_after_target = @file_reader.count_by_word_after_target(@target_word)
    count_word_after_target = @file_reader.count_word_after_target
    count_by_word = @file_reader.count_by_word

    discounted_bigram = {}
    word_count_by_count = word_count_by_count()
    sum_p = 0.0

    count_by_word.each do |word,|
      count_after_target = count_by_word_after_target[word] || 0
      word_count_by_count[count_after_target + 1] ||= 0.0

      if word_count_by_count[count_after_target] != 0
        discounted_count = (count_after_target + 1).to_f *
            word_count_by_count[count_after_target + 1].to_f /
            word_count_by_count[count_after_target].to_f
      else
        discounted_count = 0
      end

      discounted_bigram[word] = discounted_count / count_word_after_target
      sum_p += discounted_bigram[word]
    end

    [discounted_bigram, sum_p]
  end

  def word_count_by_count
    count_by_word_after_target = @file_reader.count_by_word_after_target(@target_word)
    count_by_word = @file_reader.count_by_word

    word_count_by_count = {}
    count_by_word.each do |word,|
      count = count_by_word_after_target[word] || 0

      word_count_by_count[count] ||= 0
      word_count_by_count[count] += 1
    end
    word_count_by_count
  end

  def distribution (discounted_bigram, sum_p)
    count_by_word = @file_reader.count_by_word
    count_all_word = @file_reader.count_all_word

    bigram_model = {}
    discounted_bigram.each do |word, p|
      bigram_model[word] = p + (1.0 - sum_p) * count_by_word[word].to_f / count_all_word.to_f
    end
    bigram_model
  end

  def output_to_file (bigram_model)
    File.open("#{OUTPUT_FILE_PREFIX}#{@target_word}", 'w+') do |file|
      file.write(sprintf("%20.17e\n", 0)) # for unknown word
      bigram_model.each do |, p|
        p ||= 0
        file.write(sprintf("%20.17e\n", p))
      end
    end
  end
end

bigram = Bigram.new
bigram.calc