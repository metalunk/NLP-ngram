require 'bundler'
Bundler.require

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

  CONST_D = 0.77

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
