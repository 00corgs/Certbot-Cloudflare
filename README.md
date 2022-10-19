# Certbot-Cloudflare
#説明
Certbotを使ってLet's Encryptでワイルドカード証明書を取得するシェルスクリプトです。
オプションで自動更新機能も実装予定です。
#注意
Python3が使用可能でDebian系の環境であり、ドメインのネームサーバーをCloudflareで管理している前提でシェルスクリプトが構成されています。
#使用方法
```
git clone https://github.com/00corgs/Certbot-Cloudflare
cd Certbot-Cloudflare
sudo bash installer.sh