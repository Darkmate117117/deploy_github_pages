#!/bin/bash

# チェック対象のファイル名を指定
URL_FILE="url.txt"

# --- ファイル存在チェック ---
if [ ! -f "$URL_FILE" ]; then
  echo "Error: File '$URL_FILE' not found." >&2
  exit 1
fi

url=$(grep -v '^#' "$URL_FILE" | xargs)

if [ -z "$url" ]; then
  echo "Error: URL not found in '$URL_FILE'." >&2
  exit 1
fi

# --- curl実行と結果の解析 ---
response=$(curl -s -w "\n%{http_code}" "$url")
status_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

# --- 結果の検証 ---
# ステップ1: ステータスコードを検証
if [[ "$status_code" -ge 200 && "$status_code" -lt 300 ]]; then

  # ステップ2: レスポンス内容を検証
  shopt -s nocasematch
  if [[ "$body" == *"<html"* && "$body" == *"<head"* && "$body" == *"<body"* ]]; then
    echo "Test Passed: URL is accessible and contains required HTML tags."
    exit 0
  else
    # 失敗理由: レスポンス内容が不正
    echo "Test Failed (Reason: Invalid Content): Response body does not contain required HTML tags."
    exit 1
  fi
  shopt -u nocasematch

else
  # 失敗理由: ステータスコードが不正
  echo "Test Failed (Reason: Invalid Status Code): Received $status_code"
  exit 1
fi
