module.exports = {
  theme: {
    colors: require('tailwindcss-open-color'),
    container: {
      center: true,
    },
    fill: theme => ({
      'gray': theme('colors.gray.3'),
      'yellow': theme('colors.yellow.6'),
    })
  },
  variants: {},
  plugins: [],
  purge: [
    './source/**/*.html.erb'
  ]
}
