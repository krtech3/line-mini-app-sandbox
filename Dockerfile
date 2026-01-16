# 1. ビルド用ステージ
FROM golang:1.22-bookworm AS builder

WORKDIR /app

# 依存関係のコピーとダウンロード
COPY go.mod go.sum ./
RUN go mod download

# ソースコードをコピーしてビルド
COPY . .
RUN go build -o main .

# 2. 実行用ステージ（軽量なイメージを使用）
FROM debian:bookworm-slim

WORKDIR /app

# ビルドしたバイナリをコピー
COPY --from=builder /app/main .

# ポートの公開（Renderが動的に割り当てるため、実際には参考値）
EXPOSE 8000

# 実行
CMD ["./main"]
