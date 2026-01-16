#!/usr/bin/env node
/**
 * AWS IoT Core MQTT接続サンプル (Node.js)
 * 
 * このスクリプトは、create-iot-thing.shで生成された証明書を使用して
 * AWS IoT CoreにMQTT接続し、メッセージの送受信を行います。
 * 
 * 必要なライブラリ:
 *   npm install aws-iot-device-sdk
 */

const awsIot = require('aws-iot-device-sdk');
const path = require('path');

// コマンドライン引数の処理
const args = process.argv.slice(2);
if (args.length < 2 || args.includes('--help')) {
  console.log('使用方法:');
  console.log('  node mqtt-example.js <endpoint> <thing-name> [cert-dir] [topic]');
  console.log('');
  console.log('例:');
  console.log('  node mqtt-example.js xxxxx.iot.ap-northeast-1.amazonaws.com my-iot-thing');
  console.log('  node mqtt-example.js xxxxx.iot.ap-northeast-1.amazonaws.com my-iot-thing ./certificates test/topic');
  process.exit(args.includes('--help') ? 0 : 1);
}

const endpoint = args[0];
const thingName = args[1];
const certDir = args[2] || './certificates';
const topic = args[3] || 'test/topic';

// 証明書ファイルのパス
const keyPath = path.join(certDir, `${thingName}-private.pem.key`);
const certPath = path.join(certDir, `${thingName}-certificate.pem.crt`);
const caPath = path.join(certDir, 'AmazonRootCA1.pem');

console.log('======================================');
console.log('AWS IoT Core MQTT接続を開始します');
console.log('======================================');
console.log(`エンドポイント: ${endpoint}`);
console.log(`Thing名: ${thingName}`);
console.log(`トピック: ${topic}`);
console.log('');

// デバイス接続の設定
const device = awsIot.device({
  keyPath: keyPath,
  certPath: certPath,
  caPath: caPath,
  clientId: thingName,
  host: endpoint
});

// 接続イベント
device.on('connect', () => {
  console.log('✓ AWS IoT Coreに接続しました');
  console.log('');
  
  // トピックの購読
  device.subscribe(topic);
  console.log(`✓ トピック '${topic}' を購読しました`);
  console.log('');
  
  // 定期的にメッセージを送信
  let messageCount = 0;
  setInterval(() => {
    messageCount++;
    const payload = {
      message: `Hello from ${thingName}`,
      count: messageCount,
      timestamp: new Date().toISOString()
    };
    
    console.log(`メッセージを送信: ${JSON.stringify(payload)}`);
    device.publish(topic, JSON.stringify(payload));
  }, 5000);
});

// メッセージ受信イベント
device.on('message', (receivedTopic, payload) => {
  console.log('');
  console.log('メッセージを受信:');
  console.log(`  トピック: ${receivedTopic}`);
  console.log(`  メッセージ: ${payload.toString()}`);
  console.log('');
});

// エラーイベント
device.on('error', (error) => {
  console.error('エラーが発生しました:', error);
});

// 切断イベント
device.on('close', () => {
  console.log('接続が切断されました');
});

// オフラインイベント
device.on('offline', () => {
  console.log('オフラインになりました');
});

// 再接続イベント
device.on('reconnect', () => {
  console.log('再接続中...');
});

// Ctrl+Cでの終了処理
process.on('SIGINT', () => {
  console.log('');
  console.log('終了します...');
  device.end();
  process.exit(0);
});

console.log('接続中...');
