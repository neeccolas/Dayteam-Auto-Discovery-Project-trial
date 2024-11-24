variable "region" {
  type    = string
  default = "eu-west-3"
}
variable "ami" {
  type    = string
  default = "ami-0d64bb532e0502c46"

}
variable "domain-name" {
  type    = string
  default = "dobetabeta.shop"

}
variable "domain-name-1" {
  type    = string
  default = "vault.dobetabeta.shop"
}
variable "domain-name-2" {
  type    = string
  default = "*.dobetabeta.shop"
}