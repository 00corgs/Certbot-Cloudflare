#!/bin/bash

#過去に生成したテストファイルの削除
sudo rm -f test_run.sh
#パッケージのインストール
sudo apt update
sudo apt -y install certbot python3-certbot-dns-cloudflare
if [$?=1]; then
    echo "パッケージのインストールに失敗しました。"
    exit 1
fi

echo "Cloudflareのアカウントのメールアドレスを入力してください。"
read -r email

if [ ! -e /etc/letsencrypt/cloudflare_secret.ini ];then
    echo "CloudflareのアカウントのGlobal API Keyを入力してください。"
    read -r apikey
    echo "dns_cloudflare_email = $email
    dns_cloudflare_api_key = $apikey" | sudo tee /etc/letsencrypt/cloudflare_secret.ini > /dev/null
fi
sudo chmod 600 /etc/letsencrypt/cloudflare_secret.ini

echo "登録するドメイン名を入力してください。(例:example.com)"
read -r domain

#テストファイルの作成
echo "sudo certbot certonly \
--dry-run \
--server https://acme-v02.api.letsencrypt.org/directory \
--manual --preferred-challenges dns \
--agree-tos \
--dns-cloudflare \
--dns-cloudflare-credentials /etc/letsencrypt/cloudflare_secret.ini \
--dns-cloudflare-propagation-seconds 20 \
--email $email \
-d $domain -d *.$domain" > ./_test_run.sh
sudo chmod 755 ./test_run.sh


echo ""

echo "ファイルの作成が完了しました。"
echo "テストしますか？(y|n)"
read -r test
case "$test" in
    [yY]*) ./test_run.sh
    if [$? = 1]; then
        echo "Hmm...何らかのエラーが発生したようです。解決しない場合はhttps://github.com/00corgs/Certbot-Cloudflareに知らせて頂けると幸いです。"
    fi
    ;;
    *) echo "テストをスキップします。"
    ;;
esac

echo "証明書を発行します"
sudo certbot certonly \
--server https://acme-v02.api.letsencrypt.org/directory \
--manual --preferred-challenges dns \
--agree-tos \
--dns-cloudflare \
--dns-cloudflare-credentials /etc/letsencrypt/cloudflare_secret.ini \
--dns-cloudflare-propagation-seconds 20 \
--email $email \
-d $domain -d *.$domain

if [$? = 1]; then
    echo "Hmm...何らかのエラーが発生したようです。解決しない場合はhttps://github.com/00corgs/Certbot-Cloudflareに知らせて頂けると幸いです。"
    echo "このシェルスクリプトは自動的に終了します。"
    sudo rm -f ./test_run.sh /etc/letsencrypt/cloudflare_secret.ini
    exit 1

echo "Systemdに登録しますか？(y|n)"
echo "Systemdにより毎日02:00(AM)に証明書が更新されるようになります。"
read installyn

case "$installyn" in
    [Yy]*)echo "インストールします。"
    echo "Systemd以外で手動で更新したい場合は'sudo certbot renew'を実行してください。"
    echo "[Unit]
    Description=Renew the certificate
    [Service]
    Type=oneshot
    ExecStart=certbot renew --force-renew" | tee /etc/systed/system/renew_$domain.service > /dev/null
    echo "[Unit]
    Description=Renew the certi timer
    
    [Timer]
    OnCalendar=02:00:00
    Persistent=true
    
    [Install]
    WantedBy=timers.target" | tee /etc/systed/system/renew_$domain.timer > /dev/null
    sudo systemctl enable --now renew_$domain.timer --now
    ;;
    *) echo "証明書を更新する時は'sudo certbot renew'を実行してください。"
    ;;
esac

echo "完了しました。"