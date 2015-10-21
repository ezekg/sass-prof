require_relative "../lib/sass-prof"

prof             = Sass::Prof::Config
# prof.output_file = "sass-prof.log"
# prof.quiet       = true
prof.col_width   = 40
prof.color       = true
prof.t_max       = 5

http_path = "/"
css_dir   = "stylesheets"
sass_dir  = "sass"
