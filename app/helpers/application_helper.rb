module ApplicationHelper
  # The finder with a flavor chosen (nil clears it), keeping the search.
  def flavor_filter_path(flavor)
    finder_root_path(request.query_parameters.slice("q", "lat", "lng").merge("flavor" => flavor&.slug).compact_blank)
  end

  # A flavor's lid as a round icon. Decorative wherever its name is also shown.
  def lid_icon(flavor, size:, alt: "", **options)
    image_tag flavor.lid, alt: alt, width: size, height: size, loading: "lazy", decoding: "async",
              class: class_names("shrink-0 rounded-full", options.delete(:class)), **options
  end

  # "Cilantro Lime" as a pill with its lid; the chosen flavor stands out.
  def flavor_pill(name, chosen: false)
    flavor = Flavor.named(name)
    tag.li(class: class_names("inline-flex items-center gap-1.5 rounded-full border py-0.5 pr-2.5 text-xs",
                              flavor ? "pl-0.5" : "pl-2.5",
                              chosen ? "border-ink bg-ink font-semibold text-white" : "border-line bg-white")) do
      safe_join([ (lid_icon(flavor, size: 20) if flavor), name ].compact)
    end
  end

  # "Spread the love": every share, every store.
  def love_count = @love_count ||= Share.count

  # The link a share sends: the store's own page on the full site (not the
  # jeesauce.com frame), marked so it greets the friend.
  def share_url(store) = store_url(store, shared: 1)

  def share_text(store)
    where = [ store.address_line, store.place_line ].compact_blank.join(", ")
    "Found JeeSauce whipped almond hummus at #{store.name}, #{where}. Here's where:"
  end

  # "Delivered Oct 2026 · Spotted by a shopper 3 days ago": what we know about
  # the shelf, and how old it is. Never "in stock". @spotted: rep_id => time.
  def freshness_line(store)
    parts = []
    parts << "Delivered #{store.last_delivered_on.strftime('%b %Y')}" if store.last_delivered_on
    if (seen = @spotted&.dig(store.rep_id))
      parts << "Spotted by a shopper #{seen > 1.day.ago ? 'today' : "#{time_ago_in_words(seen)} ago"}"
    end
    parts.join(" · ").presence
  end
end
