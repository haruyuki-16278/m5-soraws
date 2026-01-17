import { $ } from "jsr:@david/dax";
import { colors } from "jsr:@cliffy/ansi@1.0.0-rc.8/colors";
import { Confirm } from "jsr:@cliffy/prompt@^1.0.0-rc.8";
import { parseArgs } from "@std/cli/parse-args";

const { name } = parseArgs(Deno.args);
if (!name) {
  throw new Error(`IoT Thing の name を与えてください。`);
}

// リポジトリルートに移動
const root = await $`git rev-parse --show-toplevel`.text();
Deno.chdir(root);

// 証明書を保存するディレクトリを作成
const certDir = `.certs/${name}`;
await $`mkdir -p ${certDir}`;

// aws cliを実行するプロファイルを取得
const awsProfileRaw =
  await $`aws configure list | grep -e profile -e region | awk '{print $2}'`
    .stdout("piped");
const [profile, region] = awsProfileRaw.stdout.replaceAll(" ", "").split("\n");

// 確認
const awsProfileOk = await Confirm.prompt(
  `次のaws-cliプロファイルを使用します: ${
    colors.green(profile === "<not" ? "default" : profile)
  }@${colors.cyan(region)}`,
);
if (!awsProfileOk) {
  console.log(colors.red("終了します"));
  Deno.exit(1);
}

const nameOk = await Confirm.prompt(
  `次の名前のIoT Thingを削除します: ${colors.green(name)}`,
);
const nameAvailable = (await $`aws iot list-things`.stdout("piped")).stdout
  .includes("name");
if (!nameOk || !nameAvailable) {
  console.log(colors.red("終了します"));
  Deno.exit(1);
}

// 証明書を作成
await $`aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile ${certDir}/cert.pem \
  --private-key-outfile ${certDir}/private.key \
  --public-key-outfile ${certDir}/public.key
`;
// aws cliでthingを作成
await $`aws iot create-thing --thing-name ${name}`;
