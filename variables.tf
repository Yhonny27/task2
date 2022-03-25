variable "hostnames" {

    type        = list(string)
    description = "my hostname (i.e.: yhonathan.io"
    value       = "yhonathan.io"

}

variable "name" {

    type        = string
    description = "ghost-image"
    default     = "ghost-image"

}
