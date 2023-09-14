{ secrets, homedir, ... }:

{
  ".aws/credentials".text = secrets.aws-credentials;
  ".gnupg/pubring.gpg".source = secrets.pubring-gpg;
  ".gnupg/secring.gpg".source = secrets.secring-gpg;
  ".gnupg/trustdb.gpg".source = secrets.trustdb-gpg;
  ".gnupg/gpg-agent.conf".text = ''pinentry-program ${homedir}/.nix-profile/bin/pinentry'';
  ".ssh/id_rsa".text = secrets.id-rsa;
  ".ssh/id_rsa.pub".text = secrets.id-rsa-pub;
  ".ssh/config".text = secrets.ssh-config;
  ".ssh/ps_jaas_slave_01_rsa".text = secrets.ps-jenkins-worker-01-key;
  ".ssh/ps_jaas_slave_02_rsa".text = secrets.ps-jenkins-worker-02-key;
  ".git-credentials".text = secrets.git-credentials;
  ".config/git/work".text = secrets.git-work;
  ".config/git/personal".text = secrets.git-personal;
}
