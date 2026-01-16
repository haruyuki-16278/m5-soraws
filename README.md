# m5-soraws

AWS IoT Thingを作成し、MQTT接続に必要な証明書をダウンロードするサンプルコード集

## 概要

このリポジトリは、AWS CLIを使用してAWS IoT Thingを作成し、MQTT通信に必要な証明書をダウンロードするためのシェルスクリプトを提供します。

## 前提条件

- AWS CLIがインストールされていること（バージョン2推奨）
- AWS認証情報が設定されていること（`aws configure`）
- 適切なIAM権限があること：
  - `iot:CreateThing`
  - `iot:CreateKeysAndCertificate`
  - `iot:CreatePolicy`
  - `iot:AttachPolicy`
  - `iot:AttachThingPrincipal`
  - `iot:DescribeEndpoint`
- `jq`コマンドがインストールされていること
- `curl`コマンドがインストールされていること

## インストール

```bash
# AWS CLIのインストール（まだインストールしていない場合）
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install awscli

# jqのインストール
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

## 使い方

### AWS IoT Thingの作成と証明書のダウンロード

```bash
# デフォルトのThing名（my-iot-thing）で実行
./create-iot-thing.sh

# カスタムのThing名を指定
./create-iot-thing.sh my-custom-thing

# Thing名と証明書の保存先を指定
./create-iot-thing.sh my-custom-thing ./my-certificates
```

このスクリプトは以下の処理を実行します：

1. AWS IoT Thingの作成
2. 証明書とキーペアの作成（自動的にアクティブ化）
3. Amazon Trust Services (ATS) ルートCA証明書のダウンロード
4. IoTポリシーの作成（MQTT接続に必要な権限を付与）
5. 証明書へのポリシーのアタッチ
6. ThingへのN証明書のアタッチ
7. IoTエンドポイントの取得と表示

### 生成される証明書ファイル

デフォルトでは、`./certificates/`ディレクトリに以下のファイルが生成されます：

- `{THING_NAME}-certificate.pem.crt` - デバイス証明書
- `{THING_NAME}-private.pem.key` - 秘密鍵（**厳重に管理してください**）
- `{THING_NAME}-public.pem.key` - 公開鍵
- `AmazonRootCA1.pem` - AmazonルートCA証明書

### MQTT接続のテスト

生成された証明書を使用してMQTT接続をテストできます：

```bash
# mosquitto_pubを使用した例
mosquitto_pub --cafile ./certificates/AmazonRootCA1.pem \
  --cert ./certificates/my-iot-thing-certificate.pem.crt \
  --key ./certificates/my-iot-thing-private.pem.key \
  -h your-endpoint.iot.ap-northeast-1.amazonaws.com \
  -p 8883 \
  -t 'test/topic' \
  -m 'Hello from IoT Thing'

# mosquitto_subを使用した購読例
mosquitto_sub --cafile ./certificates/AmazonRootCA1.pem \
  --cert ./certificates/my-iot-thing-certificate.pem.crt \
  --key ./certificates/my-iot-thing-private.pem.key \
  -h your-endpoint.iot.ap-northeast-1.amazonaws.com \
  -p 8883 \
  -t 'test/topic'
```

### リソースのクリーンアップ

作成したAWS IoTリソースを削除する場合：

```bash
# デフォルトのThing名で削除
./cleanup-iot-thing.sh

# カスタムのThing名を指定して削除
./cleanup-iot-thing.sh my-custom-thing
```

このスクリプトは以下の処理を実行します：

1. Thingにアタッチされた証明書の確認
2. 証明書からThingをデタッチ
3. 証明書からポリシーをデタッチ
4. 証明書の非アクティブ化
5. 証明書の削除
6. Thingの削除
7. ポリシーの削除

**注意**: ローカルに保存された証明書ファイルは自動的に削除されません。必要に応じて手動で削除してください。

## セキュリティに関する注意事項

- **秘密鍵ファイル（`*-private.pem.key`）は絶対に公開しないでください**
- 秘密鍵は安全な場所に保管し、適切なアクセス制御を設定してください
- 証明書ファイルをGitリポジトリにコミットしないでください（`.gitignore`に追加することを推奨）
- 本番環境では、より厳格なIoTポリシーを設定してください

## トラブルシューティング

### AWS CLIの認証エラー

```bash
# AWS認証情報を設定
aws configure

# 認証情報を確認
aws sts get-caller-identity
```

### 権限エラー

IAMユーザーまたはロールに必要なIoT権限が付与されているか確認してください。

### Thing名の競合

既に同じ名前のThingが存在する場合、エラーが発生します。別の名前を使用するか、既存のThingを削除してください。

## ライセンス

MIT

## 参考リンク

- [AWS IoT Core ドキュメント](https://docs.aws.amazon.com/iot/)
- [AWS CLI IoTコマンドリファレンス](https://docs.aws.amazon.com/cli/latest/reference/iot/)
- [MQTT プロトコル](https://mqtt.org/)