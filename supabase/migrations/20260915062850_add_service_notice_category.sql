alter table public.service_notices
add column category text not null default 'service'
check (category in ('delay', 'maintenance', 'service'));
