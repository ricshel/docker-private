#!/bin/sh
set -e

# Load environment variables from the .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo ">>> Starting Ollama server..."
ollama -v
ollama serve &  
sleep 2

# Loop through each model in the MODELS list
for model in $MODELS; do
  echo ">>> Pulling $model..."
  ollama pull $model
done

echo ">>> All setup done. Holding container..."
tail -f /dev/null