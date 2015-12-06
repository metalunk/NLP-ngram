require 'bundler'
Bundler.require
autoload :FileReader, './src/file_reader'
autoload :Bigram, './src/ngram/bigram'
autoload :Trigram, './src/ngram/trigram'

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

ngram = Ngram.new
ngram.calc
