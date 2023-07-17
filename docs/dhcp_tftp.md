## DHCP (Dynamic Host Configuration Protocol):

DHCP is a network protocol that enables automatic configuration of IP addresses and related network parameters for devices on a network.

<details> 

<summary> Here's how it works: </summary> 

1. DHCP server:A DHCP server is a device or service responsible for assigning and managing IP addresses and other network configuration parameters. When a client device joins the network, it sends a DHCP request to the DHCP server.

2. IP address assignment: The DHCP server dynamically assigns an available IP address from a predefined pool of addresses to the client device. This allows for efficient IP address management and eliminates the need for manual IP configuration.

3. Network parameters: In addition to the IP address, DHCP can also provide other network parameters to the client, such as subnet mask, default gateway, DNS server addresses, and other settings. These parameters are crucial for the client device to communicate and function correctly on the network.

</details>

<details> 

<summary> Benefits of DHCP: </summary> 

1. Simplifies network administration: DHCP automates the IP address assignment process, reducing the administrative burden of manually configuring IP addresses for each device.

2. Efficient resource utilization: DHCP allows for dynamic allocation and reuse of IP addresses, ensuring efficient utilization of available IP address space.

3. Centralized management: With DHCP, network administrators can centrally manage and configure IP-related settings, making it easier to maintain and update network configurations.

</details>

<br/>

## TFTP (Trivial File Transfer Protocol):

TFTP is a simple file transfer protocol designed for lightweight and minimalistic file transfers. 

<details>

<summary> Here are some key points about TFTP: </summary>

1. File transfer: TFTP enables the transfer of files between a client and a server over a network. It is often used for transferring firmware images, configuration files, or boot files to network devices or thin clients during the boot process.

2. Connectionless protocol: TFTP operates on UDP (User Datagram Protocol) and is connectionless. This means it does not establish a persistent connection between the client and the server. Each file transfer occurs in a separate connection, making it less reliable than protocols like FTP.

3.Minimal features: TFTP has a simple design and offers minimal features compared to other file transfer protocols. It lacks authentication, encryption, and directory browsing capabilities. However, its simplicity makes it lightweight and suitable for specific use cases where speed and simplicity are prioritized over advanced features.

</details>

<details>

<summary> Use cases of TFTP: </summary>

1. Network device bootstrapping: TFTP is commonly used to transfer boot files to network devices during the boot process, such as loading firmware images or initial configurations.

2. Thin client configuration: TFTP can be used to provide configuration files or operating system images to thin clients in a networked environment.

3. Network equipment provisioning: TFTP is often employed to provision network equipment, such as routers, switches, or IP phones, with firmware updates or initial configurations.

The gist of it is in case of`On-Premise` infrastructure there exists requirements to manage bare-metals via network. Hard-drive connected with bare metals for storage purposes does not have any OS from which it could boot. Hence it looks for options via network, once it is powered on, and that's where DHCP and TFTP come into the picture.

</details>

<br/>

<p>
Here is a brief about the whole process:

1. DHCP and TFTP servers are up.
2. The boot sequence set is on a bare-metal: Hard-Drive and then Network
3. Bare metal is powered on.
4. It looks for files to boot in the hard drive. It does not find any.
5. Then it looks for files to boot over the network. The first step is to send a DHCP request over the network. It basically looks for its own IP address, TFTP server details (also known as Next server) and the bootfile name.
6. Once it gets all the above details in response from DHCP server, it connects to TFTP server and fetches: boot-loader, installation kernel, and initial ram-disk files.
7. These files help in booting the bare metal and in the end it installs an OS into the hard drive of the bare metal.
8. The bare metal then restarts, but this time since an OS is already present in the hard drive, it boots using the installed OS. That is when the bare metal becomes ready to use.

Now the installed OS can be customized in a way to install agents that can be used to configure AWS EKS-A. We will look into that in some time.

</p>

[network_boot_no_devices.png](https://github.com/hitesh-infracloud/eksa-setup/tree/master/dist/images/network_boot_no_devices.png)


The above snapshot shows a bare metal trying to boot via network, gets its IP address from DHCP server but fails to connect to TFTP server.
On analyzing the data packets, we can retrieve more information about the DHCP and TFTP requests. In the below snapshots it can be seen that the bare metal asks for TFTP server name and bootfile name as well.


[dhcp_request.png](https://github.com/hitesh-infracloud/eksa-setup/tree/master/dist/images/dhcp_request.png)


On analyzing the response of DHCP request, we can see that it gets TFTP server details and bootfile name in response.

[dhcp_response.png](https://github.com/hitesh-infracloud/eksa-setup/tree/master/dist/images/dhcp_response.png)

The below image shows how it downloads the pre boot files (vmlinuz & initramfs) once it successfully connects with TFTP server


[network_boot_with_dhcp_server.png](https://github.com/hitesh-infracloud/eksa-setup/tree/master/dist/images/network_boot_with_dhcp_server.png)