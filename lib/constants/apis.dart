import 'package:locus/widgets/RelaySelectSheet.dart';

const NOSTR_PUBLIC_RELAYS_LIST_URI = "https://api.nostr.watch/v1/public";
const NOSTR_ONLINE_RELAYS_LIST_URI = "https://api.nostr.watch/v1/online";
const NOSTR_TRENDING_PROFILES_URI =
    "https://api.nostr.band/v0/trending/profiles";

// Top 30 most used free relays
final FALLBACK_RELAYS = [
  "relay.damus.io",
  "eden.nostr.land",
  "nos.lol",
  "relay.snort.social",
  "relay.current.fyi",
  "brb.io",
  "nostr.orangepill.dev",
  "nostr-pub.wellorder.net",
  "nostr.bitcoiner.social",
  "nostr.wine",
  "nostr.oxtr.dev",
  "relay.nostr.bg",
  "nostr.mom",
  "nostr.fmt.wiz.biz",
  "relay.nostr.band",
  "nostr-pub.semisol.dev",
  "nostr.milou.lol",
  "nostr.onsats.org",
  "relay.nostr.info",
  "puravida.nostr.land",
  "offchain.pub",
  "relay.orangepill.dev",
  "no.str.cr",
  "nostr.zebedee.cloud",
  "atlas.nostr.land",
  "nostr-relay.wlvs.space",
  "relay.nostrati.com",
  "relay.nostr.com.au",
  "relay.inosta.cc",
  "nostr.rocks",
].map(addProtocol).toList();

// Strip everything after the domain for regex
final DOMAIN_REPLACE_REGEX = RegExp(r"(wss:\/\/[-\w.]+)(?:\/.*)?");
