# Example 1:

In this setup, we are creating the following:
* Using `identity` modules to create
  * Compartments
    * Two compartment under the root(account/tenant) compartment
      * first compartment name is: `applications`
        * In this compartment, we create two more compartments:
          * `ops`
          * `developments`
      * second compartment name is: `common`
  * Service Accounts:
    * `cicd-terraform`
    * `webapp-a`
  * Groups:
    * `dev`
    * `admin`
  * Users:
    * `user-1@email.com`: in group `dev`
    * `user-2@email.com`: in group `dev`
    * `user-3@email.com`: in group `admin` and `dev`.
  * Policy:
    * allow group `admin` to manage everything in the account
    * allow group `dev` to manage everything in compartment `developments`
* Using `network` module to create:
  * VCN named `developments-networks` in compartment `applications`
    * public subnet named `gateway` with cidr `192.168.4.0/24`
    * private subnet named `backend` with cidr `192.168.8.0/24`
    * private subnet named `storage` with cidr `192.168.9.0/24`
* Using `compute` module to create:
  * 1 machine named `jumpbox` in subnet `gateway` in compartment `applications`
  * 1 machines named `webapp-1` and `webapp-2` in subnet `backend` compartment `developments`
  * 1 machine named `gluster-1` in subnet `storage` in compartment `ops`
