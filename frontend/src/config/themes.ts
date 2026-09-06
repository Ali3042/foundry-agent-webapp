import {
  type BrandVariants,
  createDarkTheme,
  createLightTheme,
  type Theme,
} from '@fluentui/react-components';

// PwC-aligned warm orange ramp. These are ShareCloud application tokens rather
// than a claim to reproduce the full PwC corporate design system.
const brandColors: BrandVariants = {
  10: '#210C00',
  20: '#3A1500',
  30: '#541E00',
  40: '#6F2700',
  50: '#8A3100',
  60: '#A23A00',
  70: '#B84200',
  80: '#C94700',
  90: '#D04A02',
  100: '#DD5B10',
  110: '#EA6C1F',
  120: '#F47D2E',
  130: '#F99348',
  140: '#FCA966',
  150: '#FDC08B',
  160: '#FED7B5',
};

export const lightTheme: Theme = {
  ...createLightTheme(brandColors),
};

export const darkTheme: Theme = {
  ...createDarkTheme(brandColors),
  colorBrandForeground1: brandColors[130],
  colorBrandForeground2: brandColors[140],
  colorBrandForegroundLink: brandColors[140],
};
