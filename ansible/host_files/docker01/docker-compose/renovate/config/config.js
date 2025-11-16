module.exports = {
  endpoint: 'https://git.simn.io/',
  token: process.env.GITEA_TOKEN,
  platform: 'forgejo',
  autodiscover: true,
  onboarding: false,
  binarySource: "docker",
  dockerUser: "{{ docker_compose_user_id }}",
  hostRules: [
    {
      hostType: 'docker',
      matchHost: 'docker.io', 
      username: process.env.DOCKER_IO_USERNAME,
      password: process.env.DOCKER_IO_PASSWORD,
    },
  ],
};