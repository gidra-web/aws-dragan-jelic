import { Amplify } from 'aws-amplify';

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: "eu-central-1_5005yiWX0",
      userPoolClientId: "atp68ig74flkuscd4u8rqoini",
      signUpVerificationMethod: 'code',
      loginWith: { email: true }
    }
  },
  API: {
    REST: {
      'admin-api': {
        endpoint: "https://api.dragan.stilltesting.xyz",
        region: "eu-central-1"
      }
    }
  }
});