-- Static Klang Valley transit network data used by journey planning.
-- Times and fares are planning estimates and must not be presented as live data.

create table public.transit_lines (
  id text primary key,
  name text not null,
  short_name text not null,
  mode text not null check (mode in ('LRT', 'MRT', 'Monorail', 'KTM', 'BRT', 'Bus')),
  color text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  operator text not null default 'Rapid KL',
  active boolean not null default true
);

create table public.transit_stations (
  id text primary key,
  name text not null unique,
  latitude numeric(9, 6),
  longitude numeric(9, 6)
);

create table public.station_lines (
  station_id text not null references public.transit_stations(id) on delete cascade,
  line_id text not null references public.transit_lines(id) on delete cascade,
  stop_sequence integer not null check (stop_sequence > 0),
  is_interchange boolean not null default false,
  primary key (station_id, line_id),
  unique (line_id, stop_sequence)
);

create table public.transit_links (
  id bigint generated always as identity primary key,
  from_station_id text not null references public.transit_stations(id) on delete cascade,
  to_station_id text not null references public.transit_stations(id) on delete cascade,
  line_id text not null references public.transit_lines(id) on delete cascade,
  travel_minutes integer not null check (travel_minutes > 0),
  stop_count integer not null check (stop_count > 0),
  unique (from_station_id, to_station_id, line_id)
);

create table public.route_templates (
  id text primary key,
  origin_station_id text not null references public.transit_stations(id),
  destination_station_id text not null references public.transit_stations(id),
  label text not null,
  label_color text not null check (label_color ~ '^#[0-9A-Fa-f]{6}$'),
  duration_minutes integer not null check (duration_minutes > 0),
  fare_rm numeric(6, 2) not null check (fare_rm >= 0),
  transfers integer not null check (transfers >= 0),
  display_order integer not null default 0
);

create table public.route_template_segments (
  id bigint generated always as identity primary key,
  route_id text not null references public.route_templates(id) on delete cascade,
  segment_order integer not null check (segment_order > 0),
  segment_type text not null check (segment_type in ('walk', 'lrt', 'mrt', 'bus', 'monorail', 'ktm')),
  from_label text not null,
  to_label text not null,
  from_station_id text references public.transit_stations(id),
  to_station_id text references public.transit_stations(id),
  line_id text references public.transit_lines(id),
  duration_minutes integer not null check (duration_minutes > 0),
  stop_count integer check (stop_count is null or stop_count > 0),
  unique (route_id, segment_order)
);

create index station_lines_line_sequence_idx
  on public.station_lines (line_id, stop_sequence);
create index transit_links_from_station_idx
  on public.transit_links (from_station_id);
create index route_templates_journey_idx
  on public.route_templates (origin_station_id, destination_station_id, display_order);
create index route_template_segments_route_idx
  on public.route_template_segments (route_id, segment_order);

insert into public.transit_lines (id, name, short_name, mode, color, operator)
values
  ('kelana-jaya', 'Kelana Jaya Line', 'KJ', 'LRT', '#009FE3', 'Rapid KL'),
  ('kajang', 'MRT Kajang Line', 'MRT-K', 'MRT', '#003087', 'Rapid KL'),
  ('putrajaya', 'MRT Putrajaya Line', 'MRT-P', 'MRT', '#8B0000', 'Rapid KL'),
  ('monorail', 'KL Monorail', 'MR', 'Monorail', '#7C3AED', 'Rapid KL'),
  ('ktm-komuter', 'KTM Komuter', 'KTM', 'KTM', '#E8730A', 'Keretapi Tanah Melayu'),
  ('brt-sunway', 'BRT Sunway', 'BRT', 'BRT', '#F59E0B', 'Rapid KL'),
  ('rapid-bus', 'Rapid KL Bus', 'BUS', 'Bus', '#F59E0B', 'Rapid KL');

insert into public.transit_stations (id, name, latitude, longitude)
values
  ('kelana-jaya', 'Kelana Jaya', 3.091700, 101.606700),
  ('asia-jaya', 'Asia Jaya', 3.102100, 101.638500),
  ('taman-jaya', 'Taman Jaya', 3.103900, 101.637500),
  ('universiti', 'Universiti', 3.114700, 101.662000),
  ('kerinchi', 'Kerinchi', 3.115900, 101.669000),
  ('abdullah-hukum', 'Abdullah Hukum', 3.118600, 101.672500),
  ('bangsar', 'Bangsar', 3.127800, 101.678000),
  ('kl-sentral', 'KL Sentral', 3.134000, 101.686000),
  ('pasar-seni', 'Pasar Seni', 3.142600, 101.695800),
  ('klcc', 'KLCC', 3.159000, 101.712000),
  ('subang-jaya', 'Subang Jaya', 3.083300, 101.585000),
  ('pavilion-kl', 'Pavilion Kuala Lumpur', 3.149100, 101.713400),
  ('bukit-bintang', 'Bukit Bintang', 3.146700, 101.710800),
  ('tun-razak-exchange', 'Tun Razak Exchange', 3.141200, 101.718000),
  ('merdeka', 'Merdeka', 3.143900, 101.700900),
  ('titiwangsa', 'Titiwangsa', 3.173800, 101.695300),
  ('bukit-nanas', 'Bukit Nanas', 3.157500, 101.704400),
  ('sunway-pyramid', 'Sunway Pyramid', 3.073300, 101.607600),
  ('usj-7', 'USJ 7', 3.044700, 101.581400),
  ('ss15', 'SS15', 3.073000, 101.585500);

insert into public.station_lines (station_id, line_id, stop_sequence, is_interchange)
values
  ('kelana-jaya', 'kelana-jaya', 1, false),
  ('subang-jaya', 'kelana-jaya', 2, true),
  ('asia-jaya', 'kelana-jaya', 4, false),
  ('taman-jaya', 'kelana-jaya', 5, false),
  ('universiti', 'kelana-jaya', 6, false),
  ('kerinchi', 'kelana-jaya', 7, false),
  ('abdullah-hukum', 'kelana-jaya', 8, true),
  ('bangsar', 'kelana-jaya', 9, false),
  ('kl-sentral', 'kelana-jaya', 10, true),
  ('pasar-seni', 'kelana-jaya', 11, true),
  ('klcc', 'kelana-jaya', 14, false),
  ('merdeka', 'kajang', 15, true),
  ('bukit-bintang', 'kajang', 16, true),
  ('tun-razak-exchange', 'kajang', 17, true),
  ('titiwangsa', 'monorail', 4, true),
  ('bukit-nanas', 'monorail', 8, false),
  ('kl-sentral', 'ktm-komuter', 1, true),
  ('subang-jaya', 'ktm-komuter', 6, true),
  ('sunway-pyramid', 'brt-sunway', 2, false),
  ('usj-7', 'brt-sunway', 1, true),
  ('ss15', 'rapid-bus', 1, false);

insert into public.transit_links
  (from_station_id, to_station_id, line_id, travel_minutes, stop_count)
values
  ('asia-jaya', 'taman-jaya', 'kelana-jaya', 2, 1),
  ('taman-jaya', 'universiti', 'kelana-jaya', 2, 1),
  ('universiti', 'kerinchi', 'kelana-jaya', 2, 1),
  ('kerinchi', 'abdullah-hukum', 'kelana-jaya', 2, 1),
  ('abdullah-hukum', 'bangsar', 'kelana-jaya', 2, 1),
  ('bangsar', 'kl-sentral', 'kelana-jaya', 3, 1),
  ('kl-sentral', 'pasar-seni', 'kelana-jaya', 2, 1),
  ('pasar-seni', 'klcc', 'kelana-jaya', 6, 3),
  ('kl-sentral', 'subang-jaya', 'ktm-komuter', 25, 5),
  ('pasar-seni', 'merdeka', 'kajang', 3, 1),
  ('merdeka', 'bukit-bintang', 'kajang', 2, 1),
  ('bukit-bintang', 'tun-razak-exchange', 'kajang', 2, 1),
  ('titiwangsa', 'bukit-nanas', 'monorail', 8, 4),
  ('sunway-pyramid', 'usj-7', 'brt-sunway', 7, 2);

insert into public.route_templates
  (id, origin_station_id, destination_station_id, label, label_color, duration_minutes, fare_rm, transfers, display_order)
values
  ('asia-jaya-kl-sentral-fastest', 'asia-jaya', 'kl-sentral', 'Fastest', '#16A34A', 28, 2.50, 0, 1),
  ('asia-jaya-kl-sentral-least-walking', 'asia-jaya', 'kl-sentral', 'Least walking', '#1B4FD8', 31, 2.50, 0, 2),
  ('subang-jaya-klcc-direct', 'subang-jaya', 'klcc', 'Fastest', '#16A34A', 34, 3.60, 0, 1),
  ('subang-jaya-klcc-ktm', 'subang-jaya', 'klcc', 'Alternative', '#1B4FD8', 46, 4.00, 1, 2),
  ('kelana-jaya-bukit-bintang-mrt', 'kelana-jaya', 'bukit-bintang', 'Fastest', '#16A34A', 36, 3.20, 1, 1);

insert into public.route_template_segments
  (route_id, segment_order, segment_type, from_label, to_label, from_station_id, to_station_id, line_id, duration_minutes, stop_count)
values
  ('asia-jaya-kl-sentral-fastest', 1, 'walk', 'Current Location', 'Asia Jaya LRT', null, 'asia-jaya', null, 4, null),
  ('asia-jaya-kl-sentral-fastest', 2, 'lrt', 'Asia Jaya', 'KL Sentral', 'asia-jaya', 'kl-sentral', 'kelana-jaya', 18, 6),
  ('asia-jaya-kl-sentral-fastest', 3, 'walk', 'KL Sentral', 'Destination', 'kl-sentral', null, null, 6, null),
  ('asia-jaya-kl-sentral-least-walking', 1, 'lrt', 'Asia Jaya', 'KL Sentral', 'asia-jaya', 'kl-sentral', 'kelana-jaya', 21, 6),
  ('asia-jaya-kl-sentral-least-walking', 2, 'walk', 'KL Sentral', 'Destination', 'kl-sentral', null, null, 10, null),
  ('subang-jaya-klcc-direct', 1, 'lrt', 'Subang Jaya', 'KLCC', 'subang-jaya', 'klcc', 'kelana-jaya', 30, 13),
  ('subang-jaya-klcc-direct', 2, 'walk', 'KLCC LRT', 'Destination', 'klcc', null, null, 4, null),
  ('subang-jaya-klcc-ktm', 1, 'ktm', 'Subang Jaya', 'KL Sentral', 'subang-jaya', 'kl-sentral', 'ktm-komuter', 25, 5),
  ('subang-jaya-klcc-ktm', 2, 'walk', 'KL Sentral KTM', 'KL Sentral LRT', 'kl-sentral', 'kl-sentral', null, 6, null),
  ('subang-jaya-klcc-ktm', 3, 'lrt', 'KL Sentral', 'KLCC', 'kl-sentral', 'klcc', 'kelana-jaya', 10, 4),
  ('subang-jaya-klcc-ktm', 4, 'walk', 'KLCC LRT', 'Destination', 'klcc', null, null, 5, null),
  ('kelana-jaya-bukit-bintang-mrt', 1, 'lrt', 'Kelana Jaya', 'Pasar Seni', 'kelana-jaya', 'pasar-seni', 'kelana-jaya', 22, 10),
  ('kelana-jaya-bukit-bintang-mrt', 2, 'walk', 'Pasar Seni LRT', 'Pasar Seni MRT', 'pasar-seni', 'pasar-seni', null, 5, null),
  ('kelana-jaya-bukit-bintang-mrt', 3, 'mrt', 'Pasar Seni', 'Bukit Bintang', 'pasar-seni', 'bukit-bintang', 'kajang', 4, 2),
  ('kelana-jaya-bukit-bintang-mrt', 4, 'walk', 'Bukit Bintang MRT', 'Destination', 'bukit-bintang', null, null, 5, null);

-- Transit reference data is public, but clients must not modify it.
revoke all on table public.transit_lines, public.transit_stations,
  public.station_lines, public.transit_links, public.route_templates,
  public.route_template_segments from public, anon, authenticated;

grant select on table public.transit_lines, public.transit_stations,
  public.station_lines, public.transit_links, public.route_templates,
  public.route_template_segments to anon, authenticated;

grant select, insert, update, delete on table public.transit_lines,
  public.transit_stations, public.station_lines, public.transit_links,
  public.route_templates, public.route_template_segments to service_role;

alter table public.transit_lines enable row level security;
alter table public.transit_stations enable row level security;
alter table public.station_lines enable row level security;
alter table public.transit_links enable row level security;
alter table public.route_templates enable row level security;
alter table public.route_template_segments enable row level security;

create policy "Public can read transit lines"
  on public.transit_lines for select to anon, authenticated using (true);
create policy "Public can read transit stations"
  on public.transit_stations for select to anon, authenticated using (true);
create policy "Public can read station lines"
  on public.station_lines for select to anon, authenticated using (true);
create policy "Public can read transit links"
  on public.transit_links for select to anon, authenticated using (true);
create policy "Public can read route templates"
  on public.route_templates for select to anon, authenticated using (true);
create policy "Public can read route template segments"
  on public.route_template_segments for select to anon, authenticated using (true);