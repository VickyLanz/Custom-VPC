module "vpc" {
  source = "../Module"
  project_id = var.mproject_id
  zone = var.mzone
  region = var.mregion
  path = var.mpath
  user = var.muser
  public_key = var.mpublic_key
  privatekeypath = var.mprivatekeypath
}