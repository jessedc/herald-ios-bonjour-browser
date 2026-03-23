import SwiftUI

struct ReverseDNSInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(
                    "Reverse DNS (PTR) lookups ask \"what hostname is registered for this IP address?\" "
                    + "by querying the DNS infrastructure directly \u{2014} independent of Bonjour."
                )

                Text(
                    "When a service is resolved, Herald shows the Bonjour hostname (from the SRV record) "
                    + "and IP addresses (from address records). A PTR lookup checks whether the network's DNS "
                    + "server has a separate, \"official\" hostname registered for each of those IPs."
                )

                Text(
                    "On most home networks with a standard consumer router, PTR lookups will return no "
                    + "results \u{2014} this is normal. The feature is most useful in managed network "
                    + "environments or networks with custom DNS configuration."
                )
                
                Text("When PTR records provide new information:")
                    .fontWeight(.semibold)

                bulletPoint(
                    "Corporate or enterprise networks with DHCP-DNS integration \u{2014} your machine gets an IP, "
                    + "and the DNS server registers a hostname like \"jesse-macbook.corp.example.com\". "
                    + "That name won't appear anywhere in the Bonjour data."
                )

                bulletPoint(
                    "Home networks with Pi-hole, Unbound, or custom dnsmasq \u{2014} if you've configured "
                    + "static DHCP leases with hostnames, those show up as PTR records."
                )

                bulletPoint(
                    "Devices behind NAT or proxies \u{2014} the Bonjour name says \"Living Room Speaker\" "
                    + "but the PTR for its IP says \"gateway.local.\" because traffic is being proxied "
                    + "through the router."
                )

                bulletPoint(
                    "Misconfiguration detection \u{2014} the Bonjour name says \"printer.local.\" but PTR "
                    + "says \"old-server.local.\", revealing a reused IP or stale DNS entry."
                )
            }
            .padding()
        }
        .navigationTitle("About Reverse DNS Lookups")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
            Text(text)
        }
        .padding(.leading, 4)
    }
}
