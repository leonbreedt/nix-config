{ secrets, homedir, ... }:

{
  ".aws/credentials".source = "${secrets}/aws-credentials";
  ".gnupg/pubring.gpg".source = "${secrets}/pubring.gpg";
  ".gnupg/secring.gpg".source = "${secrets}/secring.gpg";
  ".gnupg/trustdb.gpg".source = "${secrets}/trustdb.gpg";
  ".gnupg/gpg-agent.conf".text = ''pinentry-program ${homedir}/.nix-profile/bin/pinentry'';
  ".ssh/id_rsa".source = "${secrets}/id_rsa";
  ".ssh/id_rsa.pub".source = "${secrets}/id_rsa.pub";
  ".ssh/config".source = "${secrets}/ssh-config";
  ".ssh/ps_jaas_slave_01_rsa".source = "${secrets}/ps-jenkins-worker-01.key";
  ".ssh/ps_jaas_slave_02_rsa".source = "${secrets}/ps-jenkins-worker-02.key";
  ".git-credentials".source = "${secrets}/git-credentials";
  ".config/git/work".source = "${secrets}/git-work";
  ".config/git/personal".source = "${secrets}/git-personal";
}
