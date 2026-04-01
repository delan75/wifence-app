import 'package:flutter/material.dart';

import '../theme/wifence_theme.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WiFenceColors.canvas,
      appBar: AppBar(
        title: const Text('Build log'),
      ),
      body: Stack(
        children: [
          const _LogBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: const [
              _HeroPanel(),
              SizedBox(height: 20),
              _ProgressStrip(),
              SizedBox(height: 24),
              _SectionTitle(
                title: 'Shipped so far',
                subtitle: 'A static snapshot of what WiFence already implements.',
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.4.2',
                tag: 'Control surface',
                accent: WiFenceColors.deepSea,
                title: 'In-app enforcement controls for real gateway hardening',
                summary:
                    'Encrypted DNS hardening is no longer hidden behind environment variables. WiFence now exposes a real gateway settings surface in the More tab for managing resolver-lock behavior and custom bypass targets.',
                bullets: [
                  'The gateway now exposes dedicated preferences routes for encrypted DNS hardening settings.',
                  'Owners can toggle hardening and Firefox canary handling from the app.',
                  'Custom resolver domains plus IPv4 and IPv6 targets can now be added in-app.',
                  'These controls persist on the gateway and trigger enforcement sync after changes.',
                ],
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.4.1',
                tag: 'Enforcement hardening',
                accent: WiFenceColors.cobalt,
                title: 'Encrypted DNS bypass reduction and app-specific resolver targeting',
                summary:
                    'WiFence now blocks a broader set of known encrypted DNS providers, supports Firefox-style DoH canary signaling, and allows extra resolver domains or IPs to be configured for app-specific hardening.',
                bullets: [
                  'Known encrypted DNS targets now include Cloudflare, Google, Quad9, AdGuard, OpenDNS, and NextDNS domains.',
                  'dnsmasq now serves the use-application-dns.net canary response for compatible clients that should stay on local DNS.',
                  'Encrypted DNS hardening now blocks known provider traffic on TCP 443 and 853 plus UDP 443, 784, and 8853.',
                  'Gateway configuration now supports extra encrypted DNS domains and IPs without code changes.',
                ],
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.4.0',
                tag: 'Enforcement milestone',
                accent: WiFenceColors.deepSea,
                title: 'Linux gateway execution and resolver lock foundation',
                summary:
                    'WiFence now renders real dnsmasq plus nftables enforcement artifacts, supports Linux-side application, and adds DNS lock rules to stop standard resolver bypasses.',
                bullets: [
                  'dnsmasq fragments now map blocked domains into nftables sets for category enforcement.',
                  'nftables rulesets now include full-device lockouts, category IP drops, and resolver lock redirects.',
                  'Managed devices are redirected back to local DNS on port 53 and blocked on port 853.',
                  'The gateway now exposes enforcement status and sync routes for inspection and activation.',
                ],
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.3.x',
                tag: 'Current build',
                accent: WiFenceColors.cobalt,
                title: 'Live-first gateway and reusable household flows',
                summary:
                    'WiFence now defaults to live gateway mode and supports profile-based pause, resume, bedtime, and study routines.',
                bullets: [
                  'Gateway now reports live mode by default instead of demo-first startup.',
                  'Profile routines can be applied to groups like Kids or Guests.',
                  'One-tap profile actions now support pause now, resume, bedtime, and study mode.',
                  'The app can create groups, rename them, and move devices between groups.',
                ],
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.2.x',
                tag: 'Core workflow',
                accent: WiFenceColors.mint,
                title: 'Setup, auth, discovery, and device controls',
                summary:
                    'The product moved from a visual shell into a working local-first app with protected routes and real device actions.',
                bullets: [
                  'Local owner setup and sign-in flow using bearer sessions on the gateway.',
                  'Device dashboard, device detail control, quota editing, and category blocking.',
                  'Local network discovery wired into the dashboard scan flow.',
                  'Modes tab foundation for device schedules and profile routines.',
                ],
              ),
              SizedBox(height: 14),
              _VersionCard(
                version: '0.1.x',
                tag: 'Foundation',
                accent: WiFenceColors.coral,
                title: 'Brand, shell, and product direction',
                summary:
                    'WiFence established its visual identity and moved away from generic router-admin styling.',
                bullets: [
                  'Custom design system, typography, and navigation shell.',
                  'Dashboard-first UI tailored for non-technical home users.',
                  'Local gateway architecture locked around Flutter plus FastAPI.',
                  'Core product framing narrowed to pause, schedules, limits, and categories.',
                ],
              ),
              SizedBox(height: 24),
              _SectionTitle(
                title: 'Implemented surfaces',
                subtitle: 'What already exists across mobile and gateway.',
              ),
              SizedBox(height: 14),
              _CapabilityGrid(),
              SizedBox(height: 24),
              _SectionTitle(
                title: 'Still to build',
                subtitle: 'The next pieces that turn WiFence into stronger household enforcement.',
              ),
              SizedBox(height: 14),
              _NextUpCard(),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogBackground extends StatelessWidget {
  const _LogBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.sky.withValues(alpha: 0.14),
            ),
          ),
        ),
        Positioned(
          top: 320,
          left: -80,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WiFenceColors.coral.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1C2B), WiFenceColors.deepSea, WiFenceColors.cobalt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WiFence build log',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Visible progress,\nnot hand-wavy promises.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'This screen captures what the app already does today across mobile UX, local gateway behavior, and household routine control.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatTile(
            value: '6',
            label: 'Core phases shipped',
            accent: WiFenceColors.sky,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '14+',
            label: 'Live local API routes',
            accent: WiFenceColors.mint,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: 'Now',
            label: 'Gateway mode',
            accent: WiFenceColors.coral,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.tag,
    required this.accent,
    required this.title,
    required this.summary,
    required this.bullets,
  });

  final String version;
  final String tag;
  final Color accent;
  final String title;
  final String summary;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WiFenceColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: WiFenceColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  version,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                tag,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: WiFenceColors.ink,
                ),
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WiFenceColors.ink,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityGrid extends StatelessWidget {
  const _CapabilityGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        title: 'Mobile shell',
        description: 'Custom WiFence brand system, dashboard, modes, account, and detailed device control.',
      ),
      (
        title: 'Local auth',
        description: 'Owner setup, login, bearer sessions, and protected routes on the gateway.',
      ),
      (
        title: 'Discovery',
        description: 'LAN discovery pipeline with dashboard scan flow and observed device persistence.',
      ),
      (
        title: 'Group controls',
        description: 'Profiles can be created, renamed, assigned, paused, resumed, and scheduled.',
      ),
      (
        title: 'Time controls',
        description: 'Per-device daily limits plus reusable bedtime and study-style schedules.',
      ),
      (
        title: 'Category rules',
        description: 'Live category metadata from the gateway with category block creation in-device.',
      ),
      (
        title: 'Resolver lock',
        description: 'Gateway rules now redirect standard DNS traffic and block port 853 to reduce bypass paths.',
      ),
      (
        title: 'Linux apply path',
        description: 'WiFence can now move from dry-run artifacts into actual nftables application on Linux hardware.',
      ),
      (
        title: 'Encrypted DNS hardening',
        description: 'Known DoH and resolver targets can be blocked by provider set, browser canary, and configurable app-specific domains or IPs.',
      ),
      (
        title: 'Admin controls',
        description: 'Gateway enforcement settings now have a dedicated mobile control surface instead of living only in environment config.',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: 170,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WiFenceColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: WiFenceColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WiFenceColors.ink,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard();

  @override
  Widget build(BuildContext context) {
    const nextItems = [
      'Cleaner onboarding around gateway pairing and first-network setup.',
      'True network pulse views for speed, status, and internet health.',
      'Richer analytics around schedule hits, daily summaries, and household trends.',
      'Harder bypass coverage for VPN tunnels, custom in-app proxies, and encrypted traffic that hides behind non-standard endpoints.',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5D3C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next milestone',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'WiFence already feels like a real control surface. The next leap is stronger enforcement and richer household visibility.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: WiFenceColors.ink,
                ),
          ),
          const SizedBox(height: 14),
          ...nextItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: WiFenceColors.coral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WiFenceColors.ink,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
