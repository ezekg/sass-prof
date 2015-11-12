require_relative "../lib/sass-prof"

prof             = SassProf::Config
# prof.output_file = "sass-prof.log"
# prof.quiet       = true
prof.max_width   = 40
prof.color       = true
prof.t_max       = 500
prof.precision   = 15
prof.ignore      = [
  # :fundef,
  # :fun,
  # :mixdef,
  # :mix.
  # :var,
  # :ext,
]

http_path = "/"
css_dir   = "stylesheets"
sass_dir  = "sass"
