/* eslint-disable no-console */
// Toplayıcı: tüm Cloud Function’ları modüllerden dışa aktarır
Object.assign(exports, require('./modules/usernames'));
Object.assign(exports, require('./modules/users'));
Object.assign(exports, require('./modules/reports'));
Object.assign(exports, require('./modules/admin'));
Object.assign(exports, require('./modules/ai'));
Object.assign(exports, require('./modules/webhooks'));
