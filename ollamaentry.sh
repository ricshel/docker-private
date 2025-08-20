#!/bin/sh
set -e

echo ">>> Starting Ollama server..."
ollama -v
ollama serve &  
sleep 2

echo ">>> Pulling deepseek-r1 32b..."
ollama pull deepseek-r1:32b

echo ">>> Pulling dolphin llama3 8b..."
ollama pull dolphin-llama3:8b

echo ">>> Pulling nous hermes 13b..."
ollama pull nous-hermes:13b

echo ">>> Pulling ollama pull gpt oss 20b..."
ollama pull gpt-oss:20b

echo ">>> All setup done. Holding container..."
tail -f /dev/null
