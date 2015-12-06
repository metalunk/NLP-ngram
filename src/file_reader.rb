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
