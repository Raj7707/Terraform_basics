data "template_file" "my_data" {
    template = "${file("s3-iam-policy.json")}"
    vars = {
        bucket_name = "${var.bucket_name}"
    }
}

output "name" {
    value = "${data.template_file.my_data.rendered}"
}
