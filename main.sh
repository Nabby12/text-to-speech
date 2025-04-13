#!/bin/bash

set -e

clean_markdown() {
  sed '/```/,/```/d' \
    |
    # Convert headers to sentences with periods at the end (if they don't have one already)
    sed -E 's/^(#{1,6})\s+(.*)$/\2./' \
    |
    # Remove HTML tags
    sed -E 's/<[^>]*>//g' \
    |
    # Remove markdown link syntax, keep the text
    sed -E 's/\[([^\]]+)\]\([^)]+\)/\1/g' \
    |
    # Remove image syntax
    sed -E 's/!\[([^\]]*)\]\([^)]+\)//g' \
    |
    # Remove bold and italic markers
    sed -E 's/(\*\*|\*|__|_)([^*_]*)(\*\*|\*|__|_)/\2/g' \
    |
    # Remove horizontal rules
    sed '/^[[:space:]]*[*-][[:space:]]*[*-][[:space:]]*[*-][[:space:]]*$/d' \
    |
    # Remove bullet points and replace with space
    sed -E 's/^[[:space:]]*[-*+][[:space:]]+/ /g' \
    |
    # Remove numbered lists prefixes
    sed -E 's/^[[:space:]]*[0-9]+\.[[:space:]]+/ /g' \
    |
    # Remove blockquotes
    sed -E 's/^[[:space:]]*>[[:space:]]*//g' \
    |
    # Add space after periods, question marks, and exclamation marks if not already present
    sed -E 's/([.!?])([^[:space:]])/\1 \2/g' \
    |
    # Ensure sentences end with proper punctuation
    sed -E 's/([^.!?])$/\1./g' \
    |
    # Replace multiple spaces with a single space
    tr -s ' ' \
    |
    # Make sure each paragraph ends with a period
    sed -E 's/([^.!?])\s*$/\1./g' \
    |
    # Collapse all lines into a single line
    tr '\n' ' ' \
    |
    # Remove excessive spaces
    tr -s ' ' \
    |
    # Remove spaces before punctuation
    sed -E 's/\s+([,.!?:;])/\1/g' \
    |
    # Add spaces after punctuation if not already present
    sed -E 's/([,.!?:;])([^[:space:]])/\1 \2/g' \
    |
    # Trim leading and trailing whitespace
    sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
    | cat -s
}

CLEANED_TEXT=$(cat text.md | clean_markdown | tr -d '\n')
jq --arg text "$CLEANED_TEXT" '.input.text = $text' request.json >tmp.json && mv tmp.json request.json

# ref: https://cloud.google.com/text-to-speech/docs/create-audio-text-command-line
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "x-goog-user-project: $(gcloud config get-value project)" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @request.json \
  "https://texttospeech.googleapis.com/v1/text:synthesize" | jq -r '.audioContent' >tmp.txt

base64 ./tmp.txt -d >speech.mp3

rm ./tmp.txt
