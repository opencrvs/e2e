import { utils } from "ssh2";

export function generateSSHKeyPair(): { publicKey: string; privateKey: string } {
  let keys = utils.generateKeyPairSync('ed25519');
  return { publicKey: keys.public.toString(), privateKey: keys.private.toString() };
}
