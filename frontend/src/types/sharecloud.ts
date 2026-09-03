export const INTERACTION_MODES = ['Discovery', 'Drafting'] as const;

export type InteractionMode = (typeof INTERACTION_MODES)[number];

export const INDUSTRY_CONTEXTS = [
  'Financial Services',
  'Government & Public Services',
  'Energy, Utilities & Resources',
  'Consumer Markets',
  'Industrial Manufacturing & Automotive',
  'Health Industries',
  'Technology, Media & Telecommunications',
  'Other',
] as const;

export type IndustryContext = (typeof INDUSTRY_CONTEXTS)[number] | '';

export interface ShareCloudApplicationContext {
  interactionMode: InteractionMode;
  industryContext: IndustryContext;
}

export const DEFAULT_SHARECLOUD_CONTEXT: ShareCloudApplicationContext = {
  interactionMode: 'Discovery',
  industryContext: '',
};
