{...}: {
  users.groups.shutdown = {};
  users.users.homeassistant = {
    group = "shutdown";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTwToeyPBUpY1zI0Mil9TxdpZJygx8W/0/+epVP/SIbJe+P4sBNKBoBLHJ4RnFJDhXsR0rM7/XABMw1BdDvH4AIC4CTOhOzYLda2Q+xJHO19yu63FR51nArophmbBRu5G8VdaKV4fAv4RdDFsKoar/Xee3FhwXPnhu8y0hQtVV5Kgw5nJlRPExzB392LfIrtc/e62dTbF+OD3VVnW7TKWOTJ9ngqqyashbvFONwdo6XrxW1+u9fqHQx5QXZx5N1c9F+2GB4EAZxUGOwCOTSX1CVpktjh3gi6kaHmdQ10oR+iv3vHwAbQtutDGPW6wCctZf49zu5+Z8ddh+eh+jDG8e4GczGKPyhtTE8vOTUtRpCuEMp45wmOT4aYiJWzoVRjsvoeR89Ym2CLdvProNjbKorP+7fcCdYSDDgI/DPoU2/F+a1ETxYqHKECoaphunXfHCwzjyPWSucCDKiseXee1kQKdy0aFlJI3xBKMMabR7YIe8UqWEpegFzzTJWX879hM= root@a0d7b954-ssh"
    ];
  };

  security.sudo = {
    enable = true;
    extraRules = [
      {
        commands = [
          {
            command = "/run/current-system/sw/bin/shutdown";
            options = ["NOPASSWD"];
          }
        ];
        groups = ["shutdown"];
      }
    ];
  };
}
