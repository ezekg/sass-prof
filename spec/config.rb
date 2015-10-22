require_relative "../lib/sass-prof"

prof             = Sass::Prof::Config
prof.output_file = "sass-prof.log"
# prof.quiet       = true
prof.max_width   = 40
prof.color       = false
prof.t_max       = 5
prof.precision   = 15

http_path = "/"
css_dir   = "stylesheets"
sass_dir  = "sass"
