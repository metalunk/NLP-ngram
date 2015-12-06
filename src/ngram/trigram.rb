require 'bundler'
Bundler.require

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

  CONST_D = 0.95

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
