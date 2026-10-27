import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { getConfig, updateConfig } = require('firebase-tools/lib/gcp/identityPlatform');
const project = process.argv[2];
if (!project) throw new Error('Pass your Firebase Project ID.');
const account = getGlobalDefaultAccount();
if (!account) throw new Error('Run firebase login first.');
await requireAuth({ project, ...account });
let config = await getConfig(project);
if (!config.signIn?.email?.enabled || !config.signIn?.email?.passwordRequired) {
  config = await updateConfig(project,
    { signIn: { email: { enabled: true, passwordRequired: true } } },
    'signIn.email.enabled,signIn.email.passwordRequired');
}
console.log(JSON.stringify({ project,
  emailPasswordEnabled: config.signIn?.email?.enabled === true &&
    config.signIn?.email?.passwordRequired === true }));
