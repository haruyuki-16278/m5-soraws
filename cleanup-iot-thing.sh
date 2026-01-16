#!/bin/bash

# AWS IoT Thingとリソースのクリーンアップスクリプト
# 作成したAWS IoT Thingと関連リソースを削除します

set -e

# 設定項目
THING_NAME="${1:-my-iot-thing}"
POLICY_NAME="${THING_NAME}-policy"

echo "========================================"
echo "AWS IoT Thing削除スクリプト"
echo "========================================"
echo "Thing名: ${THING_NAME}"
echo ""

# 1. Thingにアタッチされた証明書の取得
echo "1. Thingにアタッチされた証明書を確認しています..."
PRINCIPALS=$(aws iot list-thing-principals --thing-name "${THING_NAME}" 2>/dev/null | jq -r '.principals[]' || echo "")

if [ -z "${PRINCIPALS}" ]; then
    echo "警告: Thing '${THING_NAME}' に証明書がアタッチされていません"
else
    for PRINCIPAL in ${PRINCIPALS}; do
        CERT_ID=$(echo "${PRINCIPAL}" | grep -oP 'cert/\K[a-f0-9]+')
        echo "  証明書ID: ${CERT_ID}"
        
        # 2. 証明書からThingをデタッチ
        echo "2. 証明書からThingをデタッチしています..."
        aws iot detach-thing-principal \
            --thing-name "${THING_NAME}" \
            --principal "${PRINCIPAL}"
        echo "✓ Thingデタッチ完了"
        
        # 3. 証明書からポリシーをデタッチ
        echo "3. 証明書からポリシーをデタッチしています..."
        POLICIES=$(aws iot list-principal-policies --principal "${PRINCIPAL}" 2>/dev/null | jq -r '.policies[].policyName' || echo "")
        for POLICY in ${POLICIES}; do
            echo "  ポリシー: ${POLICY}"
            aws iot detach-policy \
                --policy-name "${POLICY}" \
                --target "${PRINCIPAL}"
            echo "✓ ポリシーデタッチ完了"
        done
        
        # 4. 証明書を非アクティブ化
        echo "4. 証明書を非アクティブ化しています..."
        aws iot update-certificate \
            --certificate-id "${CERT_ID}" \
            --new-status INACTIVE
        echo "✓ 証明書非アクティブ化完了"
        
        # 5. 証明書を削除
        echo "5. 証明書を削除しています..."
        aws iot delete-certificate \
            --certificate-id "${CERT_ID}"
        echo "✓ 証明書削除完了"
    done
fi

# 6. Thingの削除
echo "6. Thingを削除しています..."
aws iot delete-thing --thing-name "${THING_NAME}" 2>/dev/null || {
    echo "警告: Thing '${THING_NAME}' が見つかりません"
}
echo "✓ Thing削除完了"

# 7. ポリシーの削除
echo "7. ポリシーを削除しています..."
aws iot delete-policy --policy-name "${POLICY_NAME}" 2>/dev/null || {
    echo "警告: ポリシー '${POLICY_NAME}' が見つかりません"
}
echo "✓ ポリシー削除完了"

echo ""
echo "========================================"
echo "クリーンアップ完了！"
echo "========================================"
echo ""
echo "削除されたリソース:"
echo "  Thing名: ${THING_NAME}"
echo "  ポリシー名: ${POLICY_NAME}"
echo ""
echo "注意: ローカルの証明書ファイルは削除されていません"
echo "必要に応じて手動で削除してください"
echo ""
