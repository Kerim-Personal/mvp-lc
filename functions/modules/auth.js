/* eslint-disable no-console */
const { functions } = require('../shared');

exports.sendVerificationCode = functions.auth.user().onCreate((user) => {
  const userEmail = user.email;
  const displayName = user.displayName || 'User';
  if (!userEmail) return null;

  return null;
});
