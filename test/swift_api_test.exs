defmodule SwiftApiTest do
  use ExUnit.Case
  doctest SwiftApi

#  test "greets the world" do
#    assert SwiftApi.hello() == :world
#  end

  def identity_info do
    Poison.decode! """
  {
        "token": {
            "audit_ids": [
                "Sbog6V_AS1uExRPd5pn6XA"
            ],
            "catalog": [
                {
                    "endpoints": [
                        {
                            "id": "05263d23b71d429fb83ef24928e5330d",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://rating.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "3c46bf759c824165925d2e7f38a5ef1d",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://rating.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "9aaa2a75e49d409d9a8ca0fb3790162c",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://rating.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "15c3ddb8be2b42a1adc95c4d5875bfaf",
                    "name": "cloudkitty",
                    "type": "rating"
                },
                {
                    "endpoints": [
                        {
                            "id": "b42a0aa3981a4f72b0ccf126518744e9",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://metric.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "c8fb593626634524a653fa7eed4c0137",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://metric.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "ef59e6c6336846d89cd91f524b348da4",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://metric.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "215bf9627cfd4c8b87e8c93060ffafd1",
                    "name": "gnocchi",
                    "type": "metric"
                },
                {
                    "endpoints": [
                        {
                            "id": "aa25b3215ef7467980aa3086439112f3",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://lbaas.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "b2633180bb214add9697549087637dfb",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://lbaas.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "d2f9149bae5545b19289300c432b335f",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://lbaas.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "4421415889ad4d0cb17638a0b27cfba4",
                    "name": "octavia",
                    "type": "load-balancer"
                },
                {
                    "endpoints": [
                        {
                            "id": "1cc202920feb4a228864fd9e40093ec1",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://alarming.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "3500260420d34fdfaadd084b8a0618fd",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://alarming.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "65ddf245ff26462eaa3608a1014d9e6d",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://alarming.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "5b2506dc38224359b6e04994cd37361f",
                    "name": "aodh",
                    "type": "alarming"
                },
                {
                    "endpoints": [
                        {
                            "id": "6444eb40cebe40a29dfd87620a96314f",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v3/b31fb563c0b644c8a6a6c1da43258e88"
                        },
                        {
                            "id": "998ac597ae7e4ac4920e03f6d895bee8",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v3/b31fb563c0b644c8a6a6c1da43258e88"
                        },
                        {
                            "id": "fd577ff050f345d9adc007a4d3b9e2be",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v3/b31fb563c0b644c8a6a6c1da43258e88"
                        }
                    ],
                    "id": "6687e7f759e94dcc85e75b1ad0fda0e2",
                    "name": "cinderv3",
                    "type": "volumev3"
                },
                {
                    "endpoints": [
                        {
                            "id": "8b8eb18c6c974a3ea2b1199b9ef112b5",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://placement.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "ac56278e3eee499b84d876a5a530dce5",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://placement.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "ba4d33cf407b487b8cf5164422788ad5",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://placement.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "75024a763ab04245b9441059ea3ae909",
                    "name": "placement",
                    "type": "placement"
                },
                {
                    "endpoints": [
                        {
                            "id": "473d02476e52412daf10d171c897c49e",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v2/b31fb563c0b644c8a6a6c1da43258e88"
                        },
                        {
                            "id": "50b1ba28c0df4bb490d291e88e87291d",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v2/b31fb563c0b644c8a6a6c1da43258e88"
                        },
                        {
                            "id": "9bdab92406864ad593c2aad27e272862",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://block.os.dc-cr.b-pl.pro/v2/b31fb563c0b644c8a6a6c1da43258e88"
                        }
                    ],
                    "id": "7e261dc457fc4fc386885747ef9d1588",
                    "name": "cinderv2",
                    "type": "volumev2"
                },
                {
                    "endpoints": [
                        {
                            "id": "1fa0ce4a157d4eba95894cea2334551e",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://dns.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "2072de3a0b6445088ccf9e9ba4131148",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://dns.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "33f4093be46647549930e6103b73d697",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://dns.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "7f4e52d5449c4d61be3efae9f2295406",
                    "name": "designate",
                    "type": "dns"
                },
                {
                    "endpoints": [
                        {
                            "id": "19dba38f5aff4934b6733f0445790ee6",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://nova.os.dc-cr.b-pl.pro/v2.1"
                        },
                        {
                            "id": "78df92d82e6e4c44a8ad74d70a5fe6a1",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://nova.os.dc-cr.b-pl.pro/v2.1"
                        },
                        {
                            "id": "a5d6c9b735f64132aa6c3613b6b50c67",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://nova.os.dc-cr.b-pl.pro/v2.1"
                        }
                    ],
                    "id": "865d0d5e07d34ed49c1aabfb2630af23",
                    "name": "nova",
                    "type": "compute"
                },
                {
                    "endpoints": [
                        {
                            "id": "1c734af3f66c49b283a11fdfa019b666",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://image.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "223b20000ecb4b0f9ee6c07f6cf1aed9",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://image.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "ad87e2ca597246e89e272befb8d632eb",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://image.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "c58af8cd0f3d43afb268a5ba6a15265e",
                    "name": "glance",
                    "type": "image"
                },
                {
                    "endpoints": [
                        {
                            "id": "74b6931f15a24d75aa1b875590f59bac",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://object.os.dc-cr.b-pl.pro/v1/"
                        },
                        {
                            "id": "a66d3620a97e4c9196b6f7713b5d99de",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://object.balance-pl.ru/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88"
                        },
                        {
                            "id": "cdc3f06ce42e4a79b05497f5a3d1a8d0",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://object.os.dc-cr.b-pl.pro/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88"
                        }
                    ],
                    "id": "ccfbe934f6fd415381fa856e125d2b59",
                    "name": "swift",
                    "type": "object-store"
                },
                {
                    "endpoints": [
                        {
                            "id": "0d60267399ae4007a361d8b22012b67d",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://network.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "2014ddc72aff441281c48afe3f81ef7e",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://network.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "a8f24fd89f9c4245b7cc70c525ff640f",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://network.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "d83cd7d9c8464b6d8d505d8214c85825",
                    "name": "neutron",
                    "type": "network"
                },
                {
                    "endpoints": [
                        {
                            "id": "14ca700e1c2443f8a9d05c97688350b5",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://auth.os.dc-cr.b-pl.pro/v3/"
                        },
                        {
                            "id": "7e4fe46ceaf64427aa14a94afb6d81d4",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://auth.os.dc-cr.b-pl.pro/v3/"
                        },
                        {
                            "id": "98ca32930d3242c793a2e8f12a51b8c5",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://auth.os.dc-cr.b-pl.pro/v3/"
                        }
                    ],
                    "id": "eac428cc0470411fb38c2aa1d2cbd5d7",
                    "name": "keystone",
                    "type": "identity"
                },
                {
                    "endpoints": [
                        {
                            "id": "a2f6f9c5c4d34bd888314e987a9d7ecf",
                            "interface": "public",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://kms.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "b63600c7671047838cdf994d42c3b8ea",
                            "interface": "admin",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://kms.os.dc-cr.b-pl.pro"
                        },
                        {
                            "id": "e01bad1b1a444c8cbb76c2493cb62ea8",
                            "interface": "internal",
                            "region": "dc-cr",
                            "region_id": "dc-cr",
                            "url": "https://kms.os.dc-cr.b-pl.pro"
                        }
                    ],
                    "id": "f1851a8fc5e84dcca6daf6605794ac67",
                    "name": "barbican",
                    "type": "key-manager"
                }
            ],
            "expires_at": "2019-01-23T15:56:31.000000Z",
            "is_domain": false,
            "issued_at": "2019-01-23T11:56:31.000000Z",
            "methods": [
                "password"
            ],
            "project": {
                "domain": {
                    "id": "af578a7d3daa49fe922100ff11581fc8",
                    "name": "balance-pl"
                },
                "id": "b31fb563c0b644c8a6a6c1da43258e88",
                "name": "auto-zenit-st1"
            },
            "roles": [
                {
                    "id": "e612ec8d41ab4cdfb6a741392a3038a2",
                    "name": "swiftoperator"
                }
            ],
            "user": {
                "domain": {
                    "id": "af578a7d3daa49fe922100ff11581fc8",
                    "name": "balance-pl"
                },
                "id": "05f56d1bb86ad3cb24161d9794c4c2ee6426903b206118682e96ecef41442000",
                "name": "os-auto-zenit-st1-partnerka",
                "password_expires_at": null
            }
        }
    }
    """
  end

  test "swift url search" do
    SwiftApi.IdentityTokenWorker.update_identity_info(identity_info())
    time_now = Timex.parse!("2019-01-23T14:56:31.000000Z", "{ISO:Extended}") # one hour before expires_at
    "https://object.balance-pl.ru/v1/AUTH_b31fb563c0b644c8a6a6c1da43258e88" = SwiftApi.IdentityTokenWorker.get_swift_url(time_now)
  end

  test "swift url search when no data" do
    nil = SwiftApi.IdentityTokenWorker.get_swift_url()
  end

  test "put and receive token" do
    SwiftApi.IdentityTokenWorker.update_token("secret_token")
    "secret_token" = SwiftApi.IdentityTokenWorker.get_token()
  end

  test "check time and validity" do
    SwiftApi.IdentityTokenWorker.update_identity_info(identity_info())
    false = SwiftApi.IdentityTokenWorker.check_time_validity()
  end

  test "check time and validity one hour before expires_at" do
    time_now = Timex.parse!("2019-01-23T14:56:31.000000Z", "{ISO:Extended}") # one hour before expires_at
    SwiftApi.IdentityTokenWorker.update_identity_info(identity_info())
    true = SwiftApi.IdentityTokenWorker.check_time_validity(time_now)
  end

  test "check time and validity when no data" do
    false = SwiftApi.IdentityTokenWorker.check_time_validity()
  end
end
