output "buckets" {
  value = {
    for k, v in oci_objectstorage_bucket.bucket :
    k => { url = "https://objectstorage.**REGION_HERE**.oraclecloud.com/n/${v.namespace}/b/${v.name}" }
  }
}