class GatewayPreferences {
  const GatewayPreferences({
    required this.hardenEncryptedDns,
    required this.enableDohCanaryDomain,
    required this.extraEncryptedDnsDomains,
    required this.extraEncryptedDnsIpv4,
    required this.extraEncryptedDnsIpv6,
  });

  final bool hardenEncryptedDns;
  final bool enableDohCanaryDomain;
  final List<String> extraEncryptedDnsDomains;
  final List<String> extraEncryptedDnsIpv4;
  final List<String> extraEncryptedDnsIpv6;

  factory GatewayPreferences.fromJson(Map<String, dynamic> json) {
    return GatewayPreferences(
      hardenEncryptedDns: json['harden_encrypted_dns'] as bool? ?? false,
      enableDohCanaryDomain: json['enable_doh_canary_domain'] as bool? ?? false,
      extraEncryptedDnsDomains: _readStringList(json['extra_encrypted_dns_domains']),
      extraEncryptedDnsIpv4: _readStringList(json['extra_encrypted_dns_ipv4']),
      extraEncryptedDnsIpv6: _readStringList(json['extra_encrypted_dns_ipv6']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'harden_encrypted_dns': hardenEncryptedDns,
      'enable_doh_canary_domain': enableDohCanaryDomain,
      'extra_encrypted_dns_domains': extraEncryptedDnsDomains,
      'extra_encrypted_dns_ipv4': extraEncryptedDnsIpv4,
      'extra_encrypted_dns_ipv6': extraEncryptedDnsIpv6,
    };
  }

  GatewayPreferences copyWith({
    bool? hardenEncryptedDns,
    bool? enableDohCanaryDomain,
    List<String>? extraEncryptedDnsDomains,
    List<String>? extraEncryptedDnsIpv4,
    List<String>? extraEncryptedDnsIpv6,
  }) {
    return GatewayPreferences(
      hardenEncryptedDns: hardenEncryptedDns ?? this.hardenEncryptedDns,
      enableDohCanaryDomain: enableDohCanaryDomain ?? this.enableDohCanaryDomain,
      extraEncryptedDnsDomains:
          extraEncryptedDnsDomains ?? this.extraEncryptedDnsDomains,
      extraEncryptedDnsIpv4: extraEncryptedDnsIpv4 ?? this.extraEncryptedDnsIpv4,
      extraEncryptedDnsIpv6: extraEncryptedDnsIpv6 ?? this.extraEncryptedDnsIpv6,
    );
  }

  static List<String> _readStringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
