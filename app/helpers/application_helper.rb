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
  # jeesauce.com frame), marked so it greets the friend. via: how it was sent
  # (text, email, whatsapp, link, sheet), so an open can be counted by channel.
  def share_url(store, via) = store_url(store, shared: 1, via:)

  # The message each channel sends, written for it: short for texts, a
  # greeting and the flavors for email.
  def share_message(store, via)
    where = [ store.address_line, store.place_line ].compact_blank.join(", ")
    url = share_url(store, via)
    case via
    when "email"
      flavors = " (#{store.sorted_flavors.to_sentence})" if store.flavors.any?
      "Hi!\n\nYou have to try JeeSauce whipped almond hummus. #{store.name} carries it#{flavors}:\n#{where}\n\n" \
        "Here's the store and directions: #{url}\n"
    when "whatsapp" then "Found JeeSauce whipped almond hummus at #{store.name}, #{where} 🙌 #{url}"
    when "sheet" then "JeeSauce whipped almond hummus is at #{store.name}, #{where}."
    else "JeeSauce is at #{store.name}, #{where} 🙌 #{url}"
    end
  end

  # "In stock: November · Spotted by a shopper 3 days ago". Never a date that
  # ages ("delivered 8/28"): rep's yes/no shelf signal shown as this month,
  # and how long ago a shopper saw it. @spotted: rep_id => time.
  def freshness_line(store)
    parts = []
    parts << "In stock: #{Time.current.in_time_zone('America/Chicago').strftime('%B')}" if store.stocked_recently
    if (seen = @spotted&.dig(store.rep_id))
      parts << "Spotted by a shopper #{seen > 1.day.ago ? 'today' : "#{time_ago_in_words(seen)} ago"}"
    end
    parts.join(" · ").presence
  end

  def fresh_dot = tag.span(class: "mr-1 inline-block size-2 rounded-full bg-[#1f9d55] align-middle", aria: { hidden: true })

  # A jeesauce.com link tagged for Shopify's reports: which orders came from
  # the finder, and from which spot on it. The chosen flavor's product page
  # when there is one.
  def dtc_url(flavor = nil, spot:)
    base = flavor&.shop_url || "https://jeesauce.com"
    "#{base}?#{{ utm_source: 'findjeesauce', utm_medium: 'store_finder', utm_campaign: 'find_jeesauce', utm_content: spot }.to_query}"
  end

  # flavor name => lid image URL, for the map's popups.
  def lid_urls = Flavor.all.to_h { |f| [ f.name, image_path(f.lid) ] }
end
