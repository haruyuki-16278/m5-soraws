#!/bin/bash

# AWS IoT Thing作成とMQTT証明書ダウンロードスクリプト
# AWS IoT Thingを作成し、MQTT接続に必要な証明書をダウンロードします

set -e

# 設定項目
THING_NAME="${1:-my-iot-thing}"
CERT_DIR="${2:-./certificates}"
POLICY_NAME="${THING_NAME}-policy"

echo "========================================"
echo "AWS IoT Thing作成スクリプト"
echo "========================================"
echo "Thing名: ${THING_NAME}"
echo "証明書保存先: ${CERT_DIR}"
echo ""

# 証明書保存ディレクトリの作成
mkdir -p "${CERT_DIR}"

# 1. AWS IoT Thingの作成
echo "1. AWS IoT Thingを作成しています..."
aws iot create-thing --thing-name "${THING_NAME}" || {
    echo "警告: Thing '${THING_NAME}' は既に存在する可能性があります"
}
echo "✓ Thing作成完了"
echo ""

# 2. 証明書とキーペアの作成
echo "2. 証明書とキーペアを作成しています..."
CERT_OUTPUT=$(aws iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile "${CERT_DIR}/${THING_NAME}-certificate.pem.crt" \
    --public-key-outfile "${CERT_DIR}/${THING_NAME}-public.pem.key" \
    --private-key-outfile "${CERT_DIR}/${THING_NAME}-private.pem.key")

CERT_ARN=$(echo "${CERT_OUTPUT}" | jq -r '.certificateArn')
CERT_ID=$(echo "${CERT_OUTPUT}" | jq -r '.certificateId')

echo "✓ 証明書作成完了"
echo "  証明書ARN: ${CERT_ARN}"
echo "  証明書ID: ${CERT_ID}"
echo ""

# 3. Amazon Trust Services (ATS) ルートCA証明書のダウンロード
echo "3. AmazonルートCA証明書をダウンロードしています..."
curl -o "${CERT_DIR}/AmazonRootCA1.pem" https://www.amazontrust.com/repository/AmazonRootCA1.pem
echo "✓ ルートCA証明書ダウンロード完了"
echo ""

# 4. IoTポリシーの作成
echo "4. IoTポリシーを作成しています..."
POLICY_DOCUMENT='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Publish",
        "iot:Receive"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:Subscribe"
      ],
      "Resource": "*"
    }
  ]
}'

aws iot create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document "${POLICY_DOCUMENT}" || {
    echo "警告: ポリシー '${POLICY_NAME}' は既に存在する可能性があります"
}
echo "✓ ポリシー作成完了"
echo ""

# 5. 証明書にポリシーをアタッチ
echo "5. 証明書にポリシーをアタッチしています..."
aws iot attach-policy \
    --policy-name "${POLICY_NAME}" \
    --target "${CERT_ARN}"
echo "✓ ポリシーアタッチ完了"
echo ""

# 6. 証明書をThingにアタッチ
echo "6. 証明書をThingにアタッチしています..."
aws iot attach-thing-principal \
    --thing-name "${THING_NAME}" \
    --principal "${CERT_ARN}"
echo "✓ 証明書アタッチ完了"
echo ""

# 7. エンドポイントの取得
echo "7. IoTエンドポイントを取得しています..."
IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS | jq -r '.endpointAddress')
echo "✓ エンドポイント: ${IOT_ENDPOINT}"
echo ""

# 8. 結果の表示
echo "========================================"
echo "セットアップ完了！"
echo "========================================"
echo ""
echo "作成されたリソース:"
echo "  Thing名: ${THING_NAME}"
echo "  証明書ID: ${CERT_ID}"
echo "  ポリシー名: ${POLICY_NAME}"
echo "  エンドポイント: ${IOT_ENDPOINT}"
echo ""
echo "証明書ファイル:"
echo "  証明書: ${CERT_DIR}/${THING_NAME}-certificate.pem.crt"
echo "  秘密鍵: ${CERT_DIR}/${THING_NAME}-private.pem.key"
echo "  公開鍵: ${CERT_DIR}/${THING_NAME}-public.pem.key"
echo "  ルートCA: ${CERT_DIR}/AmazonRootCA1.pem"
echo ""
echo "MQTT接続情報:"
echo "  エンドポイント: ${IOT_ENDPOINT}"
echo "  ポート: 8883 (MQTT over TLS)"
echo ""
echo "接続テスト例:"
echo "  mosquitto_pub --cafile ${CERT_DIR}/AmazonRootCA1.pem \\"
echo "    --cert ${CERT_DIR}/${THING_NAME}-certificate.pem.crt \\"
echo "    --key ${CERT_DIR}/${THING_NAME}-private.pem.key \\"
echo "    -h ${IOT_ENDPOINT} -p 8883 \\"
echo "    -t 'test/topic' -m 'Hello from ${THING_NAME}'"
echo ""
