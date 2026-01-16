# クイックスタートガイド

## 最小限のステップでAWS IoT Thingを作成

### 1. 準備

```bash
# AWS CLIとjqがインストールされていることを確認
aws --version
jq --version

# AWS認証情報が設定されていることを確認
aws sts get-caller-identity
```

### 2. Thing作成と証明書ダウンロード

```bash
# リポジトリをクローン
git clone https://github.com/haruyuki-16278/m5-soraws.git
cd m5-soraws

# スクリプトを実行
./create-iot-thing.sh

# または、カスタム名を指定
./create-iot-thing.sh my-device-name
```

実行後、以下が作成されます：
- `./certificates/` ディレクトリ内に証明書ファイル
- AWS上にIoT Thing、証明書、ポリシー

### 3. 接続情報の確認

スクリプトの実行結果から以下の情報をメモしてください：
- **エンドポイント**: `xxxxx.iot.ap-northeast-1.amazonaws.com`
- **Thing名**: 指定した名前
- **証明書ファイルパス**

### 4. MQTT接続テスト

#### mosquitto を使用する場合:

```bash
# パッケージのインストール（Ubuntu/Debian）
sudo apt-get install mosquitto-clients

# メッセージの送信
mosquitto_pub --cafile ./certificates/AmazonRootCA1.pem \
  --cert ./certificates/my-iot-thing-certificate.pem.crt \
  --key ./certificates/my-iot-thing-private.pem.key \
  -h <エンドポイント> -p 8883 \
  -t 'test/topic' -m 'Hello IoT'

# メッセージの受信
mosquitto_sub --cafile ./certificates/AmazonRootCA1.pem \
  --cert ./certificates/my-iot-thing-certificate.pem.crt \
  --key ./certificates/my-iot-thing-private.pem.key \
  -h <エンドポイント> -p 8883 \
  -t 'test/topic'
```

#### Pythonスクリプトを使用する場合:

```bash
# 必要なライブラリをインストール
pip install AWSIoTPythonSDK

# スクリプトを実行
./mqtt-example.py --endpoint <エンドポイント> --thing-name my-iot-thing
```

### 5. リソースのクリーンアップ

テストが完了したら、不要なリソースを削除：

```bash
./cleanup-iot-thing.sh

# または、カスタム名を指定した場合
./cleanup-iot-thing.sh my-device-name
```

**注意**: ローカルの証明書ファイルは手動で削除してください：
```bash
rm -rf ./certificates
```

## トラブルシューティング

### "jq: command not found" エラー

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Amazon Linux
sudo yum install jq
```

### "Unable to locate credentials" エラー

```bash
# AWS認証情報を設定
aws configure

# または、環境変数を設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

### 権限エラー

IAMユーザーに以下のポリシーをアタッチ：
- `AWSIoTFullAccess`（開発/テスト用）
- または、カスタムポリシーで必要な権限のみ付与

### 接続タイムアウト

- エンドポイントが正しいか確認
- セキュリティグループやファイアウォールで8883ポートが開いているか確認
- 証明書ファイルのパスが正しいか確認

## 次のステップ

- [AWS IoT Core開発者ガイド](https://docs.aws.amazon.com/iot/)を参照
- IoTポリシーをカスタマイズしてセキュリティを強化
- デバイスシャドウやルールエンジンを活用
- M5Stack等のIoTデバイスで実装
