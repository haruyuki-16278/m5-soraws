#!/usr/bin/env python3
"""
AWS IoT Core MQTT接続サンプル

このスクリプトは、create-iot-thing.shで生成された証明書を使用して
AWS IoT CoreにMQTT接続し、メッセージの送受信を行います。

必要なライブラリ:
    pip install AWSIoTPythonSDK

注意: このサンプルはAWSIoTPythonSDK (v1)を使用しています。
新しいプロジェクトの場合は、AWS IoT Device SDK v2 (awsiotsdk)の使用を推奨します。
詳細: https://github.com/aws/aws-iot-device-sdk-python-v2
"""

import json
import time
import argparse
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient


def on_message_callback(client, userdata, message):
    """メッセージ受信時のコールバック関数"""
    print(f"受信: トピック={message.topic}")
    print(f"      メッセージ={message.payload.decode('utf-8')}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description='AWS IoT Core MQTT接続サンプル'
    )
    parser.add_argument(
        '--endpoint',
        required=True,
        help='AWS IoTエンドポイント (例: xxxxx.iot.ap-northeast-1.amazonaws.com)'
    )
    parser.add_argument(
        '--thing-name',
        default='my-iot-thing',
        help='Thing名 (デフォルト: my-iot-thing)'
    )
    parser.add_argument(
        '--cert-dir',
        default='./certificates',
        help='証明書ディレクトリ (デフォルト: ./certificates)'
    )
    parser.add_argument(
        '--topic',
        default='test/topic',
        help='MQTTトピック (デフォルト: test/topic)'
    )
    
    args = parser.parse_args()
    
    # 証明書ファイルのパス
    root_ca = f"{args.cert_dir}/AmazonRootCA1.pem"
    certificate = f"{args.cert_dir}/{args.thing_name}-certificate.pem.crt"
    private_key = f"{args.cert_dir}/{args.thing_name}-private.pem.key"
    
    # MQTTクライアントの初期化
    print("AWS IoT Core MQTT接続を開始します...")
    print(f"  エンドポイント: {args.endpoint}")
    print(f"  Thing名: {args.thing_name}")
    print(f"  トピック: {args.topic}")
    print()
    
    mqtt_client = AWSIoTMQTTClient(args.thing_name)
    mqtt_client.configureEndpoint(args.endpoint, 8883)
    mqtt_client.configureCredentials(root_ca, private_key, certificate)
    
    # 接続設定
    mqtt_client.configureAutoReconnectBackoffTime(1, 32, 20)
    mqtt_client.configureOfflinePublishQueueing(-1)  # 無制限
    mqtt_client.configureDrainingFrequency(2)  # 2Hz
    mqtt_client.configureConnectDisconnectTimeout(10)  # 10秒
    mqtt_client.configureMQTTOperationTimeout(5)  # 5秒
    
    # 接続
    print("接続中...")
    mqtt_client.connect()
    print("✓ 接続成功！")
    print()
    
    # トピックの購読
    print(f"トピック '{args.topic}' を購読します...")
    mqtt_client.subscribe(args.topic, 1, on_message_callback)
    print("✓ 購読開始")
    print()
    
    # メッセージの送信
    try:
        message_count = 0
        while True:
            message_count += 1
            payload = {
                'message': f'Hello from {args.thing_name}',
                'count': message_count,
                'timestamp': time.time()
            }
            
            print(f"メッセージを送信します: {payload}")
            mqtt_client.publish(
                args.topic,
                json.dumps(payload),
                1
            )
            print("✓ 送信完了")
            print()
            
            time.sleep(5)  # 5秒待機
            
    except KeyboardInterrupt:
        print("\n終了します...")
    finally:
        mqtt_client.disconnect()
        print("✓ 切断完了")


if __name__ == '__main__':
    main()
