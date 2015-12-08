# NLP-ngram

This includes programs for bigram and trigram model.

# How it works

Inputs are data file name, model name, previous words (json).
Like below

```
ruby :file_name, :model_name, :previous_words_json
```

## bigram model

```
ruby src/ngram.rb data/neko.num bigram "[28]"
```

## trigram model

```
ruby src/ngram.rb data/neko.num trigram "[24, 28]"
```
