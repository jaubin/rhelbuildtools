This package has been tested with Consul 1.5.1. If you want to use it with another release, just
update the URL in get_source_archive script. Note
that it should not work with a release older than 1.0.1 due to the fact consul now requires the
specific .json extension for its configuration files.

Note that it contains work from https://github.com/hypoport/consul-rpm-rhel6/.

It contains HashiCorp's Consul itself, which is released under the terms of the Mozilla Public License 2.0.
Project source is available here : https://github.com/hashicorp/consul/

It also contains the (almost mandatory) Consul companion Consul Template, released under the terms
of the Mozilla Public License 2.0 as well. Project source is available here :
https://github.com/hashicorp/consul-template/

